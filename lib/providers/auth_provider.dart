import 'package:flutter/foundation.dart';
import '../models/user_credentials.dart';
import '../services/auth_service.dart';
import '../services/mail_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final MailService _mailService = MailService();

  AuthStatus _status = AuthStatus.uninitialized;
  List<UserCredentials> _savedAccounts = [];
  UserCredentials? _activeCredentials;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  List<UserCredentials> get savedAccounts => _savedAccounts;
  UserCredentials? get credentials => _activeCredentials;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Checks secure storage for stored accounts on app startup
  Future<void> checkSavedCredentials() async {
    _isLoading = true;
    notifyListeners();

    try {
      _savedAccounts = await _authService.getSavedAccounts();
      _activeCredentials = await _authService.getActiveCredentials();

      if (_activeCredentials != null && _activeCredentials!.isValid) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Attempts to authenticate with IMAP and saves account if successful
  Future<bool> login(String email, String appPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final creds = UserCredentials(email: email, appPassword: appPassword);

    if (!creds.isValid) {
      _errorMessage = 'メールアドレスまたはアプリパスワード（16桁）の入力形式が不正です。';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final connectionSuccess =
        await _mailService.testConnection(creds.email, creds.appPassword);

    if (connectionSuccess) {
      await _authService.saveAccount(creds, setActive: true);
      _savedAccounts = await _authService.getSavedAccounts();
      _activeCredentials = creds;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage =
          'IMAP接続テストに失敗しました。\nGmailアドレスとアプリパスワードを確認してください。';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Switches active account to selected credentials
  Future<void> switchAccount(UserCredentials target) async {
    _isLoading = true;
    notifyListeners();

    await _authService.switchActiveAccount(target.email);
    _activeCredentials = target;
    _status = AuthStatus.authenticated;

    _isLoading = false;
    notifyListeners();
  }

  /// Removes a saved account
  Future<void> removeAccount(String email) async {
    _isLoading = true;
    notifyListeners();

    await _authService.removeAccount(email);
    _savedAccounts = await _authService.getSavedAccounts();
    _activeCredentials = await _authService.getActiveCredentials();

    if (_activeCredentials == null) {
      _status = AuthStatus.unauthenticated;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Logs out of all accounts and clears secure storage
  Future<void> logoutAll() async {
    await _authService.clearAllCredentials();
    _savedAccounts = [];
    _activeCredentials = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }
}
