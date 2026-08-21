import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/env_config.dart';
import 'auth_service.dart';

/// Best-practice RevenueCat Service managing cross-platform entitlement,
/// user identification, duplicate purchase guards, and restoration logic.
class PurchaseService {
  static const String entitlementId = 'pro_features';
  static const String _keyProUnlockedDevice = 'app_is_pro_unlocked_v2';
  static bool _isInitialized = false;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Saves local device Pro status to allow device-wide account sharing
  static Future<void> saveProStatusLocally(bool isPro) async {
    try {
      if (isPro) {
        await _storage.write(key: _keyProUnlockedDevice, value: 'true');
      }
    } catch (e) {
      debugPrint('[PurchaseService] saveProStatusLocally error: $e');
    }
  }

  /// Checks if device has locally unlocked Pro
  static Future<bool> isProUnlockedLocally() async {
    try {
      final value = await _storage.read(key: _keyProUnlockedDevice);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Clears local Pro status (e.g. on full logout)
  static Future<void> clearLocalProStatus() async {
    try {
      await _storage.delete(key: _keyProUnlockedDevice);
    } catch (e) {
      debugPrint('[PurchaseService] clearLocalProStatus error: $e');
    }
  }

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
      if (isProFromCustomerInfo(result.customerInfo)) {
        await saveProStatusLocally(true);
      }
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
      await clearLocalProStatus();
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

  /// Checks if any of the saved Gmail accounts (or current RevenueCat user) has active Pro status
  static Future<bool> isProUser([List<String>? emailsToCheck]) async {
    if (!_isInitialized) await init();
    if (!_isInitialized) return await isProUnlockedLocally();

    try {
      // 1. Collect all saved Gmail accounts to check
      List<String> emails = emailsToCheck != null ? List<String>.from(emailsToCheck) : [];
      if (emails.isEmpty) {
        final accounts = await AuthService().getSavedAccounts();
        emails = accounts.map((a) => a.email.trim().toLowerCase()).toList();
      }

      // Also ensure current active email is in the list
      final activeCreds = await AuthService().getActiveCredentials();
      final activeEmail = activeCreds?.email.trim().toLowerCase();
      if (activeEmail != null && activeEmail.isNotEmpty && !emails.contains(activeEmail)) {
        emails.insert(0, activeEmail);
      }

      if (emails.isEmpty) {
        // Fallback: check current RevenueCat customer if no accounts saved
        final customerInfo = await Purchases.getCustomerInfo();
        final isPro = isProFromCustomerInfo(customerInfo);
        if (isPro) {
          await saveProStatusLocally(true);
          return true;
        } else {
          await clearLocalProStatus();
          return false;
        }
      }

      // 2. Check each saved email against RevenueCat
      bool anyProFound = false;
      for (final email in emails) {
        try {
          final loginResult = await Purchases.logIn(email);
          if (isProFromCustomerInfo(loginResult.customerInfo)) {
            anyProFound = true;
            debugPrint('[PurchaseService] Pro entitlement found for account: $email');
            break;
          }
        } catch (e) {
          debugPrint('[PurchaseService] Error checking email $email: $e');
        }
      }

      // 3. Ensure active session is restored to the current active email
      if (activeEmail != null && activeEmail.isNotEmpty) {
        try {
          await Purchases.logIn(activeEmail);
        } catch (_) {}
      }

      if (anyProFound) {
        await saveProStatusLocally(true);
        return true;
      } else {
        await clearLocalProStatus();
        return false;
      }
    } catch (e) {
      debugPrint('[PurchaseService] isProUser error: $e');
      return await isProUnlockedLocally();
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
            await saveProStatusLocally(true);
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

        // Handle configuration error (Code 23) in debug mode to allow local testing without App Store Connect
        if (errorCode == PurchasesErrorCode.configurationError) {
          debugPrint('[PurchaseService] ConfigurationError caught. Falling back to local test unlock in debug mode.');
          if (kDebugMode) {
            await saveProStatusLocally(true);
            return true;
          }
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
        if (kDebugMode) {
          await saveProStatusLocally(true);
          return true;
        }
        rethrow;
      }
    }

    return await isProUnlockedLocally();
  }

  /// Restores previous in-app purchases and updates entitlement status
  static Future<bool> restorePurchases() async {
    if (!_isInitialized) await init();

    if (_isInitialized) {
      try {
        debugPrint('[PurchaseService] Restoring purchases...');
        final customerInfo = await Purchases.restorePurchases();
        final isPro = isProFromCustomerInfo(customerInfo);
        if (isPro) {
          await saveProStatusLocally(true);
        } else {
          await clearLocalProStatus();
        }
        debugPrint('[PurchaseService] Restore result pro_features active: $isPro');
        return isPro;
      } catch (e) {
        debugPrint('[PurchaseService] Restore Error: $e');
        rethrow;
      }
    }

    return await isProUnlockedLocally();
  }
}
