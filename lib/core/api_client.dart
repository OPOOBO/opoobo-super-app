import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dio_factory.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(),
      _dio = DioFactory.create();

  Dio get dio => _dio;

  // Token management
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'sso_access_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'sso_access_token');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'sso_access_token');
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password, 'device_name': 'OPOOBO'},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> logout() async {
    final response = await _dio.post('/auth/logout');
    return response.data;
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final response = await _dio.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _dio.post(
      '/auth/reset-password',
      data: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return response.data;
  }

  // User endpoints
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/user/profile');
    return response.data;
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _dio.get('/user/stats');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile({
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.put('/user/profile', data: data);
    return response.data;
  }
}
