import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'sso_service.dart';

/// Single source of truth for Dio configuration. Every API client
/// should use [create] instead of building its own Dio instance.
class DioFactory {
  DioFactory._();

  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://one.opoobo.com/api/v1',
  );

  static const Duration _connectTimeout = Duration(seconds: 15);
  static const Duration _receiveTimeout = Duration(seconds: 15);

  static const Map<String, String> _defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// Create a Dio instance with the standard app config.
  ///
  /// If [baseUrl] is null, uses the default OPOOBO backend URL.
  /// If [addAuth] is true, attaches the SSO token interceptor and
  /// 401-retry logic.
  static Dio create({String? baseUrl, bool addAuth = true}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? _defaultBaseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        headers: _defaultHeaders,
      ),
    );

    if (addAuth) {
      dio.interceptors.add(_SsoAuthInterceptor());
    }

    return dio;
  }

  /// Create a Dio instance for external services that don't need auth
  /// (e.g. Keycloak userinfo).
  static Dio createExternal({String? baseUrl, Duration? receiveTimeout}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: _connectTimeout,
        receiveTimeout: receiveTimeout ?? _receiveTimeout,
        headers: _defaultHeaders,
      ),
    );
  }
}

/// Shared SSO auth interceptor — attaches access token and retries on 401.
class _SsoAuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'sso_access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;
    if (err.response?.statusCode == 401 && req.extra['sso_retried'] != true) {
      try {
        final newToken = await SsoService().refreshOnce();
        if (newToken != null && newToken.isNotEmpty) {
          req.headers['Authorization'] = 'Bearer $newToken';
          req.extra['sso_retried'] = true;
          final retry = await Dio().fetch(req);
          return handler.resolve(retry);
        }
      } catch (_) {}
    }
    handler.next(err);
  }
}
