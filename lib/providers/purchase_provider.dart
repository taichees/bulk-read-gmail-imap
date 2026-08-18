import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/purchase_service.dart';

class PurchaseProvider extends ChangeNotifier {
  bool _isPro = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentEmail;

  bool get isPro => _isPro;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentEmail => _currentEmail;

  /// Initializes RevenueCat and checks initial status
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await PurchaseService.init(isDebug: kDebugMode);
      _isPro = await PurchaseService.isProUser();
    } catch (e) {
      _isPro = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Identifies user with Gmail address for cross-platform entitlement sharing
  Future<void> identifyUser(String email) async {
    _isLoading = true;
    _currentEmail = email;
    notifyListeners();

    try {
      await PurchaseService.identifyUser(email);
      _isPro = await PurchaseService.isProUser();
    } catch (e) {
      _isPro = await PurchaseService.isProUnlockedLocally();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resets RevenueCat session when user logs out
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await PurchaseService.logout();
      _isPro = false;
      _currentEmail = null;
    } catch (e) {
      _isPro = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-evaluates current Pro entitlement status (revocation/refund check)
  Future<void> checkProStatus() async {
    try {
      final status = await PurchaseService.isProUser();
      if (_isPro != status) {
        _isPro = status;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[PurchaseProvider] checkProStatus error: $e');
    }
  }

  /// Triggers purchase flow
  Future<bool> buyPro([Package? package]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await PurchaseService.purchasePackage(package);
      if (success) {
        await PurchaseService.saveProStatusLocally(true);
        _isPro = true;
      } else {
        _isPro = await PurchaseService.isProUser();
      }
      return success;
    } catch (e) {
      _errorMessage = '購入処理中にエラーが発生しました: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restores previous purchases
  Future<bool> restorePurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await PurchaseService.restorePurchases();
      _isPro = success;
      if (!success) {
        _errorMessage = '復元可能なプロ版の購入情報が見つかりませんでした。';
      }
      return success;
    } catch (e) {
      _errorMessage = '復元処理中にエラーが発生しました: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
