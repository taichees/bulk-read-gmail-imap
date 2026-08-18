import 'package:flutter/foundation.dart';
import '../models/user_credentials.dart';
import '../services/mail_service.dart';

class MailProvider extends ChangeNotifier {
  final MailService _mailService = MailService();

  bool _isProcessing = false;
  MailResult? _lastResult;
  String? _errorMessage;

  bool get isProcessing => _isProcessing;
  MailResult? get lastResult => _lastResult;
  String? get errorMessage => _errorMessage;

  /// Executes bulk read operation on IMAP
  Future<MailResult> executeBulkRead({
    required UserCredentials credentials,
    required bool isPro,
  }) async {
    if (_isProcessing) {
      return MailResult(
        success: false,
        errorMessage: '処理中です。完了までお待ちください。',
      );
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _mailService.markAllAsRead(
      email: credentials.email,
      appPassword: credentials.appPassword,
      isPro: isPro,
    );

    _isProcessing = false;
    _lastResult = result;
    if (!result.success) {
      _errorMessage = result.errorMessage;
    }
    notifyListeners();

    return result;
  }
}
