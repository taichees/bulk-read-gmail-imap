import 'package:flutter/foundation.dart';
import '../services/purchase_service.dart';

class PurchaseProvider extends ChangeNotifier {
  final PurchaseService _purchaseService = PurchaseService();

  bool _isPro = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isPro => _isPro;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initializes RevenueCat and updates Pro status
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _purchaseService.init().timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );
      _isPro = await _purchaseService.checkProStatus().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
    } catch (e) {
      _isPro = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Triggers RevenueCat purchase flow
  Future<bool> buyPro() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _purchaseService.makePurchase();
      _isPro = success;
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
      final success = await _purchaseService.restorePurchases();
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
