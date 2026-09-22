import 'package:flutter/foundation.dart';
import '../core/user_api_client.dart';
import '../models/user_models.dart';

class AddressProvider extends ChangeNotifier {
  final _api = UserApiClient();
  List<AddressData> _addresses = [];
  bool _loading = false;

  List<AddressData> get addresses => _addresses;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _addresses = await _api.getAddresses();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<bool> add({
    required String label,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    String? country,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    try {
      final address = await _api.addAddress(
        label: label,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        country: country,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );
      _addresses.insert(0, address);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(int id, Map<String, dynamic> fields) async {
    try {
      final address = await _api.updateAddress(id, fields);
      final idx = _addresses.indexWhere((a) => a.id == id);
      if (idx >= 0) _addresses[idx] = address;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(int id) async {
    try {
      await _api.deleteAddress(id);
      _addresses.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
