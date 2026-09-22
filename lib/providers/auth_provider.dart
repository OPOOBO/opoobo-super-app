import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/sso_service.dart';
import '../core/module_api_client.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final SsoService _sso = SsoService();
  final ModuleApiClient _moduleApi = ModuleApiClient();

  AuthState _state = AuthState.initial;
  Map<String, dynamic>? _user;
  String? _errorMessage;

  AuthState get state => _state;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  String get initials {
    if (_user == null) return '?';
    final name = _user!['name'] as String? ?? '';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get displayName => _user?['name'] as String? ?? 'User';
  String get displayEmail => _user?['email'] as String? ?? '';
  String get displayPhone => _user?['phone_number'] as String? ?? '';
  String get memberTier => _user?['membership_tier'] as String? ?? 'basic';
  String get opooboId => _user?['sub'] as String? ?? '';

  String get memberTierLabel {
    final tier = memberTier;
    return tier[0].toUpperCase() + tier.substring(1);
  }

  List<Map<String, dynamic>> get linkedModules {
    final modules = _user?['modules'] as List<dynamic>? ?? [];
    return modules.cast<Map<String, dynamic>>();
  }

  // ── Check Auth Status on App Start ────────────────────────────────
  Future<void> checkAuthStatus() async {
    final startedAt = DateTime.now();

    final hasSession = await _sso.hasValidSession();
    if (!hasSession) {
      await _minSplashDelay(startedAt);
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final newToken = await _sso.refresh();
      if (newToken == null) {
        await _sso.logout();
        _state = AuthState.unauthenticated;
        await _minSplashDelay(startedAt);
        notifyListeners();
        return;
      }

      _user = await _sso.getStoredProfile();
      _state = AuthState.authenticated;

      // Best-effort: link bus + market silently so services show
      // as linked without asking the user for extra details.
      await _autoLinkModules();
    } catch (e) {
      await _sso.logout();
      _state = AuthState.unauthenticated;
    }

    await _minSplashDelay(startedAt);
    notifyListeners();
  }

  Future<void> _minSplashDelay(DateTime startedAt) async {
    const minDuration = Duration(milliseconds: 1600);
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }
  }

  // ── Login with Keycloak SSO ──────────────────────────────────────
  Future<bool> login() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _sso.login();

      if (profile == null || profile.isEmpty) {
        _errorMessage = 'Login failed. Please try again.';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }

      _user = _mapKeycloakProfile(profile);

      // Auto-link all services in the background
      await _autoLinkModules();

      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  // ── Public retry: silent re-link without asking user for details ──
  // Called by Bus screen when the UID isn't loaded yet.
  Future<bool> ensureModulesLinked() async {
    if (_user == null) return false;
    final before = linkedModules.length;
    await _autoLinkModules();
    return linkedModules.isNotEmpty || before > 0;
  }

  // ── Auto-link all modules using Keycloak ID ──────────────────────
  Future<void> _autoLinkModules() async {
    if (_user == null) return;

    try {
      // Fresh id_token — bus/market SSO endpoints reject expired ones.
      final idToken = await _sso.getValidIdToken();
      final result = await _moduleApi.autoLinkModules(
        keycloakSub: _user!['sub'] ?? '',
        email: _user!['email'] ?? '',
        name: _user!['name'] ?? '',
        phone: _user!['phone_number'],
        idToken: idToken,
      );

      if (result['success'] == true && result['data'] != null) {
        // Merge linked modules info into user profile
        _user!['modules'] = result['data']['modules'] ?? [];
      }
    } catch (e) {
      // Auto-link failed silently — modules will show as unlinked
    }
  }

  // ── Logout ───────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _sso.logout();
    } catch (_) {}
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  // ── Map Keycloak profile to app user format ──────────────────────
  Map<String, dynamic> _mapKeycloakProfile(Map<String, dynamic> kc) {
    final name =
        kc['name'] as String? ??
        '${kc['given_name'] ?? ''} ${kc['family_name'] ?? ''}'.trim();
    return {
      'sub': kc['sub'] ?? '',
      'name': name.isNotEmpty ? name : (kc['preferred_username'] ?? 'User'),
      'email': kc['email'] ?? '',
      'phone_number': kc['phone_number'] ?? '',
      'preferred_username': kc['preferred_username'] ?? '',
      'email_verified': kc['email_verified'] ?? false,
      'modules': <Map<String, dynamic>>[],
    };
  }
}
