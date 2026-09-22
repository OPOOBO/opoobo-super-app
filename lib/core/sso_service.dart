import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'sso_config.dart';

class SsoService {
  static final SsoService _instance = SsoService._();
  factory SsoService() => _instance;
  SsoService._();

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'sso_access_token';
  static const _refreshTokenKey = 'sso_refresh_token';
  static const _idTokenKey = 'sso_id_token';
  static const _userProfileKey = 'sso_user_profile';

  // ── Login with Keycloak PKCE ────────────────────────────────────
  Future<Map<String, dynamic>?> login() async {
    try {
      final request = AuthorizationTokenRequest(
        SsoConfig.clientId,
        SsoConfig.redirectUrl,
        issuer: SsoConfig.issuer,
        scopes: SsoConfig.scopes,
        preferEphemeralSession: false,
      );

      final result = await _appAuth.authorizeAndExchangeCode(request);

      // Save tokens
      await _storage.write(key: _accessTokenKey, value: result.accessToken);
      await _storage.write(key: _refreshTokenKey, value: result.refreshToken);
      await _storage.write(key: _idTokenKey, value: result.idToken);

      // Try id_token first, fallback to /userinfo endpoint
      Map<String, dynamic> profile = _decodeIdToken(result.idToken);

      if (profile.isEmpty && result.accessToken != null) {
        profile = await _fetchUserInfo(result.accessToken!);
      }

      await _storage.write(key: _userProfileKey, value: jsonEncode(profile));
      return profile;
    } catch (e) {
      return null;
    }
  }

  // ── Refresh Token ───────────────────────────────────────────────
  // Single-flight wrapper: concurrent 401s share one refresh call.
  Future<String?>? _refreshInFlight;
  Future<String?> refreshOnce() {
    final ongoing = _refreshInFlight;
    if (ongoing != null) return ongoing;
    final future = refresh();
    _refreshInFlight = future;
    future.whenComplete(() => _refreshInFlight = null);
    return future;
  }

  Future<String?> refresh() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return null;

    try {
      final result = await _appAuth.token(
        TokenRequest(
          SsoConfig.clientId,
          SsoConfig.redirectUrl,
          issuer: SsoConfig.issuer,
          refreshToken: refreshToken,
          scopes: SsoConfig.scopes,
        ),
      );

      if (result.accessToken != null) {
        await _storage.write(key: _accessTokenKey, value: result.accessToken);
      }
      if (result.refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: result.refreshToken);
      }
      // Keycloak returns a fresh id_token on refresh — persist it so
      // SSO auto-link (bus/market) never sends a stale one.
      if (result.idToken != null) {
        await _storage.write(key: _idTokenKey, value: result.idToken);
      }
      return result.accessToken;
    } catch (e) {
      return null;
    }
  }

  // ── Logout ──────────────────────────────────────────────────────
  Future<void> logout() async {
    final idToken = await _storage.read(key: _idTokenKey);
    try {
      await _appAuth.endSession(
        EndSessionRequest(
          idTokenHint: idToken,
          postLogoutRedirectUrl: SsoConfig.redirectUrl,
          issuer: SsoConfig.issuer,
        ),
      );
    } catch (_) {}
    await _clearAll();
  }

  // ── Check Auth Status ───────────────────────────────────────────
  Future<bool> hasValidSession() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getStoredProfile() async {
    final profileStr = await _storage.read(key: _userProfileKey);
    if (profileStr == null) return null;
    return jsonDecode(profileStr) as Map<String, dynamic>;
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getIdToken() async {
    return await _storage.read(key: _idTokenKey);
  }

  /// Returns a non-expired id_token, refreshing once when the stored one
  /// is missing or expired. Market SSO endpoints reject stale tokens, so
  /// auto-link / chat / favourites must use this instead of getIdToken().
  Future<String?> getValidIdToken() async {
    try {
      final current = await _storage.read(key: _idTokenKey);
      if (current != null && !_isExpired(current)) return current;
      await refreshOnce();
      return await _storage.read(key: _idTokenKey);
    } catch (_) {
      return null;
    }
  }

  bool _isExpired(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return true;
      var payload = parts[1];
      payload += '=' * ((4 - payload.length % 4) % 4);
      final json = jsonDecode(utf8.decode(base64Url.decode(payload)));
      final exp = (json as Map)['exp'];
      if (exp is! num) return true;
      // 30s leeway for clock skew + request time.
      return DateTime.now().millisecondsSinceEpoch > exp.toInt() * 1000 - 30000;
    } catch (_) {
      return true;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _fetchUserInfo(String accessToken) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        '${SsoConfig.issuer}/protocol/openid-connect/userinfo',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {};
    }
  }

  Map<String, dynamic> _decodeIdToken(String? idToken) {
    if (idToken == null) return {};
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return {};
      final payload = utf8.decode(base64Url.decode(parts[1]));
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _clearAll() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _idTokenKey);
    await _storage.delete(key: _userProfileKey);
  }
}
