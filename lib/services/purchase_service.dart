import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/env_config.dart';

/// Best-practice RevenueCat Service managing cross-platform entitlement,
/// user identification, duplicate purchase guards, and restoration logic.
class PurchaseService {
  static const String entitlementId = 'pro_features';
  static bool _isInitialized = false;

  /// Initializes RevenueCat SDK using configured API key
  static Future<void> init({bool isDebug = false}) async {
    if (_isInitialized) return;

    if (!EnvConfig.isConfigured) {
      _isInitialized = false;
      debugPrint('[PurchaseService] Configured environment file is missing.');
      return;
    }

    final apiKey = EnvConfig.revenueCatApiKey;

    try {
      await Purchases.setLogLevel(isDebug ? LogLevel.debug : LogLevel.info);
      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      _isInitialized = true;
      debugPrint('[PurchaseService] RevenueCat initialized with key: $apiKey');
    } catch (e) {
      _isInitialized = false;
      debugPrint('[PurchaseService] RevenueCat init failed: $e');
    }
  }

  /// Binds user's Gmail address as RevenueCat App User ID for cross-platform sharing
  static Future<CustomerInfo?> identifyUser(String email) async {
    if (!_isInitialized) await init();
    if (!_isInitialized) return null;

    try {
      final cleanEmail = email.trim().toLowerCase();
      debugPrint('[PurchaseService] Identifying user with email: $cleanEmail');
      final result = await Purchases.logIn(cleanEmail);
      return result.customerInfo;
    } catch (e) {
      debugPrint('[PurchaseService] identifyUser error: $e');
      return null;
    }
  }

  /// Resets RevenueCat session on logout
  static Future<CustomerInfo?> logout() async {
    if (!_isInitialized) return null;

    try {
      debugPrint('[PurchaseService] Logging out RevenueCat user session.');
      final customerInfo = await Purchases.logOut();
      return customerInfo;
    } catch (e) {
      debugPrint('[PurchaseService] logout error: $e');
      return null;
    }
  }

  /// Helper to evaluate if CustomerInfo grants Pro status (checking entitlements AND purchased products)
  static bool isProFromCustomerInfo(CustomerInfo? customerInfo) {
    if (customerInfo == null) return false;
    final hasActiveEntitlement = (customerInfo.entitlements.all[entitlementId]?.isActive == true) ||
        customerInfo.entitlements.active.isNotEmpty;
    final hasPurchasedProduct = customerInfo.allPurchasedProductIdentifiers.contains(entitlementId) ||
        customerInfo.allPurchasedProductIdentifiers.isNotEmpty;

    return hasActiveEntitlement || hasPurchasedProduct;
  }

  /// Checks if active entitlement for 'pro_features' exists or if any product has been purchased
  static Future<bool> isProUser() async {
    if (!_isInitialized) await init();
    if (!_isInitialized) return false;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPro = isProFromCustomerInfo(customerInfo);
      debugPrint('[PurchaseService] isProUser check: $isPro (entitlements: ${customerInfo.entitlements.active.keys}, purchasedProducts: ${customerInfo.allPurchasedProductIdentifiers})');
      return isPro;
    } catch (e) {
      debugPrint('[PurchaseService] isProUser error: $e');
      return false;
    }
  }

  /// Triggers purchase flow with strict duplicate check and productAlreadyPurchasedError handling
  static Future<bool> purchasePackage([Package? packageToPurchase]) async {
    if (!_isInitialized) await init();

    // 1. Strict Guard against duplicate purchase if user is already Pro
    if (await isProUser()) {
      debugPrint('[PurchaseService] User is already Pro. Blocking duplicate purchase attempt.');
      return true;
    }

    if (_isInitialized) {
      try {
        Package? package = packageToPurchase;

        // If package not provided, search available offerings
        if (package == null) {
          final offerings = await Purchases.getOfferings();
          final targetOffering = offerings.current ??
              offerings.all['default'] ??
              (offerings.all.isNotEmpty ? offerings.all.values.first : null);

          if (targetOffering != null && targetOffering.availablePackages.isNotEmpty) {
            package = targetOffering.availablePackages.first;
          }
        }

        if (package != null) {
          debugPrint('[PurchaseService] Purchasing package: ${package.identifier}');
          final customerInfo = await Purchases.purchasePackage(package);
          final isEntitled = isProFromCustomerInfo(customerInfo);

          if (isEntitled) {
            return true;
          }
        } else {
          debugPrint('[PurchaseService] No package available for purchase.');
        }
      } on PlatformException catch (e) {
        final errorCode = PurchasesErrorHelper.getErrorCode(e);

        if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
          debugPrint('[PurchaseService] Purchase cancelled by user.');
          return false;
        }

        // Handle already purchased error by restoring purchases
        if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
          debugPrint('[PurchaseService] Product already purchased error caught. Triggering restore.');
          return await restorePurchases();
        }

        debugPrint('[PurchaseService] PlatformException during purchase: ${e.message}');
        rethrow;
      } catch (e) {
        debugPrint('[PurchaseService] Error during purchase: $e');
        rethrow;
      }
    }

    return false;
  }

  /// Restores previous in-app purchases and updates entitlement status
  static Future<bool> restorePurchases() async {
    if (!_isInitialized) await init();

    if (_isInitialized) {
      try {
        debugPrint('[PurchaseService] Restoring purchases...');
        final customerInfo = await Purchases.restorePurchases();
        final isPro = isProFromCustomerInfo(customerInfo);
        debugPrint('[PurchaseService] Restore result pro_features active: $isPro');
        return isPro;
      } catch (e) {
        debugPrint('[PurchaseService] Restore Error: $e');
        rethrow;
      }
    }

    return false;
  }
}
