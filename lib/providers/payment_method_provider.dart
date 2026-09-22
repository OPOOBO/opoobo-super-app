import 'package:flutter/foundation.dart';
import '../core/user_api_client.dart';
import '../models/user_models.dart';

class PaymentMethodProvider extends ChangeNotifier {
  final _api = UserApiClient();
  List<PaymentMethodData> _methods = [];
  bool _loading = false;

  List<PaymentMethodData> get methods => _methods;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _methods = await _api.getPaymentMethods();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<bool> add({
    required String type,
    required String provider,
    required String lastFour,
    String? expiryMonth,
    String? expiryYear,
    String? bankName,
    String? accountNumberMasked,
    bool isDefault = false,
  }) async {
    try {
      final method = await _api.addPaymentMethod(
        type: type,
        provider: provider,
        lastFour: lastFour,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        bankName: bankName,
        accountNumberMasked: accountNumberMasked,
        isDefault: isDefault,
      );
      _methods.insert(0, method);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(int id) async {
    try {
      await _api.deletePaymentMethod(id);
      _methods.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setDefault(int id) async {
    try {
      await _api.setDefaultPaymentMethod(id);
      for (final m in _methods) {
        m == _methods.firstWhere((m) => m.id == id)
            ? null
            : null; // no-op, just rebuild
      }
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
