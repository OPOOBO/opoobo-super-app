import 'package:flutter/foundation.dart';
import '../core/user_api_client.dart';
import '../models/user_models.dart';

class SavedLocationProvider extends ChangeNotifier {
  final _api = UserApiClient();
  List<SavedLocationData> _locations = [];
  bool _loading = false;

  List<SavedLocationData> get locations => _locations;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _locations = await _api.getSavedLocations();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<bool> add({
    required String name,
    required String type,
    String? code,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final loc = await _api.addSavedLocation(
        name: name,
        type: type,
        code: code,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      _locations.insert(0, loc);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(int id) async {
    try {
      await _api.deleteSavedLocation(id);
      _locations.removeWhere((l) => l.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
