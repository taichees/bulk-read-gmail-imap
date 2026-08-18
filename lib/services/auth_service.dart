import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_credentials.dart';

class AuthService {
  static const String _keyAccountsJson = 'gmail_accounts_list_v2';
  static const String _keyActiveEmail = 'gmail_active_email_v2';

  // Legacy keys for migration
  static const String _legacyKeyEmail = 'gmail_user_email';
  static const String _legacyKeyAppPassword = 'gmail_app_password';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Gets all saved accounts from secure storage
  Future<List<UserCredentials>> getSavedAccounts() async {
    try {
      final jsonStr = await _storage.read(key: _keyAccountsJson);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        return list
            .map((item) => UserCredentials.fromJson(item as Map<String, dynamic>))
            .where((cred) => cred.isValid)
            .toList();
      }

      // Check legacy single-account storage if multi-account list is not set
      final legacyEmail = await _storage.read(key: _legacyKeyEmail);
      final legacyPassword = await _storage.read(key: _legacyKeyAppPassword);

      if (legacyEmail != null &&
          legacyPassword != null &&
          legacyEmail.isNotEmpty &&
          legacyPassword.isNotEmpty) {
        final creds = UserCredentials(
          email: legacyEmail,
          appPassword: legacyPassword,
        );
        return [creds];
      }
    } catch (e) {
      // Return empty list on storage exception
    }
    return [];
  }

  /// Gets the currently active account credentials
  Future<UserCredentials?> getActiveCredentials() async {
    final accounts = await getSavedAccounts();
    if (accounts.isEmpty) return null;

    try {
      final activeEmail = await _storage.read(key: _keyActiveEmail);
      if (activeEmail != null && activeEmail.isNotEmpty) {
        final found = accounts.firstWhere(
          (a) => a.email.toLowerCase() == activeEmail.toLowerCase(),
          orElse: () => accounts.first,
        );
        return found;
      }
    } catch (e) {
      // Fall back to first account on error
    }
    return accounts.first;
  }

  /// Saves or updates an account credentials, and optionally sets as active
  Future<void> saveAccount(
    UserCredentials credentials, {
    bool setActive = true,
  }) async {
    final accounts = await getSavedAccounts();
    final index = accounts.indexWhere(
      (a) => a.email.toLowerCase() == credentials.email.toLowerCase(),
    );

    if (index >= 0) {
      accounts[index] = credentials;
    } else {
      accounts.add(credentials);
    }

    final jsonStr = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _storage.write(key: _keyAccountsJson, value: jsonStr);

    if (setActive) {
      await _storage.write(key: _keyActiveEmail, value: credentials.email);
    }
  }

  /// Sets specified email as active account
  Future<void> switchActiveAccount(String email) async {
    final accounts = await getSavedAccounts();
    final exists = accounts.any(
      (a) => a.email.toLowerCase() == email.toLowerCase(),
    );
    if (exists) {
      await _storage.write(key: _keyActiveEmail, value: email);
    }
  }

  /// Removes an account by email
  Future<void> removeAccount(String email) async {
    final accounts = await getSavedAccounts();
    accounts.removeWhere(
      (a) => a.email.toLowerCase() == email.toLowerCase(),
    );

    final jsonStr = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _storage.write(key: _keyAccountsJson, value: jsonStr);

    final activeEmail = await _storage.read(key: _keyActiveEmail);
    if (activeEmail != null &&
        activeEmail.toLowerCase() == email.toLowerCase()) {
      if (accounts.isNotEmpty) {
        await _storage.write(key: _keyActiveEmail, value: accounts.first.email);
      } else {
        await _storage.delete(key: _keyActiveEmail);
      }
    }
  }

  /// Clears all stored credentials
  Future<void> clearAllCredentials() async {
    await _storage.delete(key: _keyAccountsJson);
    await _storage.delete(key: _keyActiveEmail);
    await _storage.delete(key: _legacyKeyEmail);
    await _storage.delete(key: _legacyKeyAppPassword);
  }
}
