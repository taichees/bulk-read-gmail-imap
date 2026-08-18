import 'dart:io';

class EnvConfig {
  /// RevenueCat iOS Public API Key passed via --dart-define-from-file
  static const String revenueCatApiKeyIOS = String.fromEnvironment(
    'REVENUECAT_KEY_IOS',
    defaultValue: '',
  );

  /// RevenueCat Android Public API Key passed via --dart-define-from-file
  static const String revenueCatApiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_KEY_ANDROID',
    defaultValue: '',
  );

  /// Active RevenueCat API Key based on current OS platform
  static String get revenueCatApiKey {
    return Platform.isIOS ? revenueCatApiKeyIOS : revenueCatApiKeyAndroid;
  }

  /// Whether current run is a production release
  static const bool isProduction = bool.fromEnvironment(
    'IS_PRODUCTION',
    defaultValue: false,
  );

  /// Checks if environment configuration was properly passed via --dart-define-from-file
  static bool get isConfigured {
    final key = revenueCatApiKey.trim();
    return key.isNotEmpty &&
        !key.contains('YOUR_REVENUECAT') &&
        !key.contains('YOUR_TEST_STORE_KEY');
  }
}
