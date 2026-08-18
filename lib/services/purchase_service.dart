import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  static const String entitlementId = 'pro_features';
  
  // NOTE: Replace with your actual RevenueCat API Keys
  static const String _revenueCatApiKeyIOS = 'appl_YOUR_REVENUECAT_IOS_KEY';
  static const String _revenueCatApiKeyAndroid = 'goog_YOUR_REVENUECAT_ANDROID_KEY';

  bool _isInitialized = false;

  /// Initializes RevenueCat SDK
  Future<void> init() async {
    if (_isInitialized) return;
    
    final apiKey = Platform.isIOS ? _revenueCatApiKeyIOS : _revenueCatApiKeyAndroid;

    // Skip initialization if placeholder API key is used to avoid blocking/hanging
    if (apiKey.contains('YOUR_REVENUECAT')) {
      _isInitialized = false;
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.debug);
      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }
  }

  /// Checks if active entitlement for 'pro_features' exists
  Future<bool> checkProStatus() async {
    if (!_isInitialized) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Triggers purchase flow for Pro package
  Future<bool> makePurchase() async {
    if (!_isInitialized) await init();
    if (!_isInitialized) return false;
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        final package = offerings.current!.availablePackages.first;
        final customerInfo = await Purchases.purchasePackage(package);
        return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
      }
      return false;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        rethrow;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Restores previous in-app purchases
  Future<bool> restorePurchases() async {
    if (!_isInitialized) await init();
    if (!_isInitialized) return false;
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }
}
