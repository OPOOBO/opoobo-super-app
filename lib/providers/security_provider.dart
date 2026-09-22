import 'package:flutter/foundation.dart';
import '../core/user_api_client.dart';
import '../models/user_models.dart';

class SecurityProvider extends ChangeNotifier {
  final _api = UserApiClient();
  List<LoginSessionData> _sessions = [];
  bool _loading = false;

  List<LoginSessionData> get sessions => _sessions;
  bool get loading => _loading;
  LoginSessionData? get currentSession =>
      _sessions.where((s) => s.isCurrent).firstOrNull;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _sessions = await _api.getLoginHistory();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<bool> revokeSession(int id) async {
    try {
      await _api.revokeSession(id);
      _sessions.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
