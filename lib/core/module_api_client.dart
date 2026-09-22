import 'package:dio/dio.dart';
import 'dio_factory.dart';

class ModuleApiClient {
  final Dio _dio;

  ModuleApiClient() : _dio = DioFactory.create();

  Dio get dio => _dio;

  // ── Get all modules with link status ──────────────────────────────
  Future<Map<String, dynamic>> getModules() async {
    final response = await _dio.get('/modules');
    return response.data;
  }

  // ── Check email across modules ────────────────────────────────────
  Future<Map<String, dynamic>> checkEmail({required String email}) async {
    final response = await _dio.post('/modules/check-email', data: {
      'email': email,
    });
    return response.data;
  }

  // ── Link existing module account ──────────────────────────────────
  Future<Map<String, dynamic>> linkModule({
    required String moduleName,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/modules/link', data: {
      'module_name': moduleName,
      'email': email,
      'password': password,
    });
    return response.data;
  }

  // ── Create new module account ─────────────────────────────────────
  Future<Map<String, dynamic>> createModuleAccount({
    required String moduleName,
    required Map<String, dynamic> extraFields,
  }) async {
    final response = await _dio.post('/modules/create-account', data: {
      'module_name': moduleName,
      'extra_fields': extraFields,
    });
    return response.data;
  }

  // ── Unlink module ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> unlinkModule({required String moduleName}) async {
    final response = await _dio.post('/modules/unlink', data: {
      'module_name': moduleName,
    });
    return response.data;
  }

  // ── Update password on module ─────────────────────────────────────
  Future<Map<String, dynamic>> updateModulePassword({
    required String moduleName,
    required String newPassword,
  }) async {
    final response = await _dio.put('/modules/update-password', data: {
      'module_name': moduleName,
      'new_password': newPassword,
    });
    return response.data;
  }

  // ── Check if specific module is linked ────────────────────────────
  Future<bool> isModuleLinked(String moduleName) async {
    try {
      final response = await getModules();
      if (response['success'] == true) {
        final modules = response['data']['modules'] as List<dynamic>? ?? [];
        final module = modules.firstWhere(
          (m) => m['name'] == moduleName,
          orElse: () => null,
        );
        return module != null && module['is_linked'] == true;
      }
    } catch (_) {}
    return false;
  }

  // ── Get module UID ────────────────────────────────────────────────
  Future<String?> getModuleUid(String moduleName) async {
    try {
      final response = await getModules();
      if (response['success'] == true) {
        final modules = response['data']['modules'] as List<dynamic>? ?? [];
        final module = modules.firstWhere(
          (m) => m['name'] == moduleName,
          orElse: () => null,
        );
        return module?['module_uid'];
      }
    } catch (_) {}
    return null;
  }

  // ── Auto-link all modules using Keycloak ID ──────────────────────
  Future<Map<String, dynamic>> autoLinkModules({
    required String keycloakSub,
    required String email,
    required String name,
    String? phone,
    String? idToken,
  }) async {
    final response = await _dio.post('/modules/auto-link', data: {
      'keycloak_sub': keycloakSub,
      'email': email,
      'name': name,
      'phone': phone,
      'id_token': idToken,
    });
    return response.data;
  }

  // ── Store: browse available mini-apps ─────────────────────────────
  Future<Map<String, dynamic>> storeBrowse({
    String? category,
    bool? featured,
    String? query,
  }) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;
    if (featured == true) params['featured'] = '1';
    if (query != null && query.isNotEmpty) params['q'] = query;

    final response = await _dio.get('/store', queryParameters: params);
    return response.data;
  }

  // ── Store: submit a new mini-app ──────────────────────────────────
  Future<Map<String, dynamic>> storeSubmit({
    required String displayName,
    required String description,
    required String moduleUrl,
    required String developerName,
    String? developerUrl,
    String? category,
    String? icon,
  }) async {
    final response = await _dio.post('/store/submit', data: {
      'display_name': displayName,
      'description': description,
      'module_url': moduleUrl,
      'developer_name': developerName,
      'developer_url': developerUrl,
      'category': category,
      'icon': icon,
    });
    return response.data;
  }

  // ── Store: record install ─────────────────────────────────────────
  Future<Map<String, dynamic>> storeInstall(int moduleId) async {
    final response = await _dio.post('/store/install/$moduleId');
    return response.data;
  }

  // ── Store: check for version update ───────────────────────────────
  Future<Map<String, dynamic>> storeVersionCheck(String moduleName, {String current = '0.0.0'}) async {
    final response = await _dio.get('/store/$moduleName/version', queryParameters: {'current': current});
    return response.data;
  }

  // ── Store: get mini-app detail ────────────────────────────────────
  Future<Map<String, dynamic>> storeDetail(int moduleId) async {
    final response = await _dio.get('/mini-apps/$moduleId');
    return response.data;
  }
}
