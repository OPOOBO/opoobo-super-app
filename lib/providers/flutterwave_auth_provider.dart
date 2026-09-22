import 'package:flutter/foundation.dart';
import '../core/user_api_client.dart';
import '../models/user_models.dart';

class FlutterwaveAuthProvider extends ChangeNotifier {
  final _api = UserApiClient();
  List<SavedAuthorizationData> _authorizations = [];
  bool _loading = false;

  List<SavedAuthorizationData> get authorizations => _authorizations;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _authorizations = await _api.getAuthorizations();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<bool> save({
    required String authorizationCode,
    required String cardType,
    required String lastFour,
    String? expMonth,
    String? expYear,
    String? bankName,
  }) async {
    try {
      final auth = await _api.storeAuthorization(
        authorizationCode: authorizationCode,
        cardType: cardType,
        lastFour: lastFour,
        expMonth: expMonth,
        expYear: expYear,
        bankName: bankName,
      );
      // Upsert into list
      _authorizations.removeWhere((a) => a.authorizationCode == authorizationCode);
      _authorizations.insert(0, auth);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> chargeSaved({
    required String authorizationCode,
    required double amount,
    required String currency,
    required String email,
    required String txRef,
  }) async {
    return await _api.chargeSaved(
      authorizationCode: authorizationCode,
      amount: amount,
      currency: currency,
      email: email,
      txRef: txRef,
    );
  }

  Future<bool> remove(int id) async {
    try {
      await _api.deleteAuthorization(id);
      _authorizations.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
