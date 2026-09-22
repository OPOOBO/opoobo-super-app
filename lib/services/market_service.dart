import 'package:dio/dio.dart';
import '../core/dio_factory.dart';
import '../core/sso_service.dart';

/// Upstream envelope: success = {error: false, ...}, failure =
/// {error: true|string, ...}. Our own 401s use a string error.
bool marketSuccess(Map<String, dynamic>? res) =>
    res != null && res['error'] == false;

class MarketService {
  final Dio _dio;

  MarketService() : _dio = DioFactory.create();

  /// Payload add-on for market-auth endpoints: a fresh id_token lets the
  /// backend mint the market token on demand when none is stored yet.
  Future<Map<String, dynamic>> _authed([Map<String, dynamic>? data]) async {
    final idToken = await SsoService().getValidIdToken();
    return {'id_token': idToken, ...?data};
  }

  // ── Public ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getHome() async => _post('/market/home');
  Future<Map<String, dynamic>?> getItems({
    Map<String, dynamic>? filters,
  }) async => _post('/market/items', filters ?? {});
  Future<Map<String, dynamic>?> getItemDetail(String slug) async =>
      _post('/market/items/$slug', await _authed());
  Future<Map<String, dynamic>?> getCategories() async =>
      _get('/market/categories');
  Future<Map<String, dynamic>?> getReels({int? page}) async =>
      _post('/market/reels', {'page': page});
  Future<Map<String, dynamic>?> getJobs() async => _get('/market/jobs');
  Future<Map<String, dynamic>?> search(String query) async =>
      _post('/market/search', {'search': query, 'status': 'approved'});

  // ── Auth-required ──────────────────────────────────────────────
  Future<Map<String, dynamic>?> getNotifications() async =>
      _post('/market/notifications', await _authed());
  Future<Map<String, dynamic>?> getMyOffers() async =>
      _post('/market/offer-list', await _authed({'type': 'buyer'}));
  Future<Map<String, dynamic>?> createPaymentIntent(
    Map<String, dynamic> data,
  ) async => _post('/market/payment-intent', await _authed(data));
  Future<Map<String, dynamic>?> getChatList({int? page}) async => _post(
    '/market/chat-list',
    await _authed({'page': page, 'type': 'buyer'}),
  );
  Future<Map<String, dynamic>?> getChatMessages({
    required int offerId,
    int? page,
  }) async => _post(
    '/market/chat-messages',
    await _authed({'item_offer_id': offerId, 'page': page}),
  );
  Future<Map<String, dynamic>?> sendMessage({
    required int offerId,
    required String message,
  }) async => _post(
    '/market/send-message',
    await _authed({'item_offer_id': offerId, 'message': message}),
  );
  Future<Map<String, dynamic>?> makeOffer({
    required int itemId,
    String? amount,
  }) async => _post(
    '/market/item-offer',
    await _authed({'item_id': itemId, 'amount': ?amount}),
  );
  Future<Map<String, dynamic>?> applyToJob(Map<String, dynamic> data) async =>
      _post('/market/job-apply', await _authed(data));
  Future<Map<String, dynamic>?> toggleFavourite(
    Map<String, dynamic> data,
  ) async => _post('/market/favourite', await _authed(data));
  Future<Map<String, dynamic>?> getFavourites({int? page, int? limit}) async =>
      _post(
        '/market/favourites',
        await _authed({'page': page, 'limit': limit ?? 50}),
      );
  Future<Map<String, dynamic>?> getReportReasons() async =>
      _post('/market/report-reasons', {});
  Future<Map<String, dynamic>?> reportItem({
    required int itemId,
    int? reasonId,
    String? message,
  }) async => _post(
    '/market/report-item',
    await _authed({
      'item_id': itemId,
      'report_reason_id': ?reasonId,
      if (message != null && message.isNotEmpty) 'other_message': message,
    }),
  );
  Future<Map<String, dynamic>?> submitReview({
    required int itemId,
    required double rating,
    String? review,
  }) async => _post(
    '/market/submit-review',
    await _authed({
      'item_id': itemId,
      'ratings': rating,
      if (review != null && review.isNotEmpty) 'review': review,
    }),
  );

  // ── Helpers ────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final res = await _dio.get(path);
      return res.data;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _post(
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      final res = await _dio.post(path, data: data);
      return res.data;
    } catch (_) {
      return null;
    }
  }
}
