import 'package:dio/dio.dart';
import '../core/dio_factory.dart';
import '../models/user_models.dart';

class UserApiClient {
  final Dio _dio;

  UserApiClient() : _dio = DioFactory.create();

  // ── Payment Methods ─────────────────────────────────────────────
  Future<List<PaymentMethodData>> getPaymentMethods() async {
    final res = await _dio.get('/payment-methods');
    final data = res.data['data'] as List;
    return data.map((j) => PaymentMethodData.fromJson(j)).toList();
  }

  Future<PaymentMethodData> addPaymentMethod({
    required String type,
    required String provider,
    required String lastFour,
    String? expiryMonth,
    String? expiryYear,
    String? bankName,
    String? accountNumberMasked,
    bool isDefault = false,
  }) async {
    final res = await _dio.post('/payment-methods', data: {
      'type': type,
      'provider': provider,
      'last_four': lastFour,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'bank_name': bankName,
      'account_number_masked': accountNumberMasked,
      'is_default': isDefault,
    });
    return PaymentMethodData.fromJson(res.data['data']);
  }

  Future<void> deletePaymentMethod(int id) async {
    await _dio.delete('/payment-methods/$id');
  }

  Future<void> setDefaultPaymentMethod(int id) async {
    await _dio.put('/payment-methods/$id/default');
  }

  // ── Addresses ───────────────────────────────────────────────────
  Future<List<AddressData>> getAddresses() async {
    final res = await _dio.get('/addresses');
    final data = res.data['data'] as List;
    return data.map((j) => AddressData.fromJson(j)).toList();
  }

  Future<AddressData> addAddress({
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
    final res = await _dio.post('/addresses', data: {
      'label': label,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
    });
    return AddressData.fromJson(res.data['data']);
  }

  Future<AddressData> updateAddress(int id, Map<String, dynamic> fields) async {
    final res = await _dio.put('/addresses/$id', data: fields);
    return AddressData.fromJson(res.data['data']);
  }

  Future<void> deleteAddress(int id) async {
    await _dio.delete('/addresses/$id');
  }

  // ── Saved Locations ─────────────────────────────────────────────
  Future<List<SavedLocationData>> getSavedLocations() async {
    final res = await _dio.get('/saved-locations');
    final data = res.data['data'] as List;
    return data.map((j) => SavedLocationData.fromJson(j)).toList();
  }

  Future<SavedLocationData> addSavedLocation({
    required String name,
    required String type,
    String? code,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _dio.post('/saved-locations', data: {
      'name': name,
      'type': type,
      'code': code,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    });
    return SavedLocationData.fromJson(res.data['data']);
  }

  Future<void> deleteSavedLocation(int id) async {
    await _dio.delete('/saved-locations/$id');
  }

  // ── Security ────────────────────────────────────────────────────
  Future<List<LoginSessionData>> getLoginHistory() async {
    final res = await _dio.get('/security/login-history');
    final data = res.data['data'] as List;
    return data.map((j) => LoginSessionData.fromJson(j)).toList();
  }

  Future<void> revokeSession(int id) async {
    await _dio.delete('/security/sessions/$id');
  }

  Future<void> recordLogin() async {
    await _dio.post('/security/record-login');
  }

  // ── Flutterwave Saved Authorizations ────────────────────────────
  Future<List<SavedAuthorizationData>> getAuthorizations() async {
    final res = await _dio.get('/flutterwave/authorizations');
    final data = res.data['data'] as List;
    return data.map((j) => SavedAuthorizationData.fromJson(j)).toList();
  }

  Future<SavedAuthorizationData> storeAuthorization({
    required String authorizationCode,
    required String cardType,
    required String lastFour,
    String? expMonth,
    String? expYear,
    String? bankName,
  }) async {
    final res = await _dio.post('/flutterwave/authorizations', data: {
      'authorization_code': authorizationCode,
      'card_type': cardType,
      'last_four': lastFour,
      'exp_month': expMonth,
      'exp_year': expYear,
      'bank_name': bankName,
    });
    return SavedAuthorizationData.fromJson(res.data['data']);
  }

  Future<Map<String, dynamic>> chargeSaved({
    required String authorizationCode,
    required double amount,
    required String currency,
    required String email,
    required String txRef,
  }) async {
    final res = await _dio.post('/flutterwave/charge-saved', data: {
      'authorization_code': authorizationCode,
      'amount': amount,
      'currency': currency,
      'email': email,
      'tx_ref': txRef,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> verifyTransaction(String txRef) async {
    final res = await _dio.get('/flutterwave/verify/$txRef');
    return res.data;
  }

  Future<void> deleteAuthorization(int id) async {
    await _dio.delete('/flutterwave/authorizations/$id');
  }
}
