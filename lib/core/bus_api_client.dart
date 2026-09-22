import 'package:dio/dio.dart';
import '../models/bus/city.dart';
import '../models/bus/bus_search_result.dart';
import '../models/bus/bus_layout.dart';
import '../models/bus/boarding_point.dart';
import '../models/bus/operator.dart';
import '../models/bus/booking.dart';
import '../models/bus/coupon.dart';

class BusApiClient {
  static const String _baseUrl = 'https://tapp.bus.opoobo.com/api';

  static const String flutterwavePublicKey = String.fromEnvironment(
    'FLW_PK',
    defaultValue: 'FLWPUBK-068b3e07fc228e9cd307949e2a251977-X',
  );

  final Dio _dio;

  BusApiClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

  /// Helper to extract the standard bus API response envelope.
  Map<String, dynamic> _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) return responseData;
    return {'Result': 'false', 'ResponseMsg': 'Invalid response'};
  }

  bool _isSuccess(Map<String, dynamic> res) =>
      res['Result']?.toString().toLowerCase() == 'true';

  // ── City List ──────────────────────────────────────────────────────
  Future<List<City>> getCityList() async {
    final res = _unwrap((await _dio.post('/citylist.php', data: {})).data);
    if (!_isSuccess(res)) return [];
    return (res['citylist'] as List<dynamic>? ?? [])
        .map((c) => City.fromJson(c))
        .toList();
  }

  // ── Search Buses ──────────────────────────────────────────────────
  Future<BusSearchResponse> searchBuses({
    required String uid,
    required String boardingId,
    required String dropId,
    required String tripDate,
    int sort = 0,
    int pickupFilter = 0,
    int dropFilter = 0,
    int busType = 0,
    String operatorList = '0',
    String facilityList = '0',
  }) async {
    final res = _unwrap(
      (await _dio.post(
        '/bus_search.php',
        data: {
          'uid': uid,
          'boarding_id': boardingId,
          'drop_id': dropId,
          'trip_date': tripDate,
          'sort': sort,
          'pickupfilter': pickupFilter,
          'dropfilter': dropFilter,
          'bustype': busType,
          'operatorlist': operatorList,
          'facilitylist': facilityList,
        },
      )).data,
    );
    if (!_isSuccess(res)) {
      return BusSearchResponse(buses: [], currency: 'NGN');
    }
    final rawCurrency = res['currency']?.toString() ?? '';
    return BusSearchResponse(
      buses: (res['BusData'] as List<dynamic>? ?? [])
          .map((b) => BusSearchResult.fromJson(b))
          .toList(),
      currency: rawCurrency.length == 3 ? rawCurrency.toUpperCase() : 'NGN',
    );
  }

  // ── Bus Layout + Packages ─────────────────────────────────────────
  Future<BusLayout?> getBusLayout({
    required String uid,
    required String busId,
    required String tripDate,
  }) async {
    final res = _unwrap(
      (await _dio.post(
        '/bus_layout.php',
        data: {'uid': uid, 'bus_id': busId, 'trip_date': tripDate},
      )).data,
    );
    if (!_isSuccess(res)) return null;
    return BusLayout.fromJson(res);
  }

  // ── Boarding / Dropping Points ────────────────────────────────────
  Future<BoardingDropResponse> getBoardingPoints({
    required String uid,
    required String idPickupDrop,
  }) async {
    final res = _unwrap(
      (await _dio.post(
        '/boarding_dropping_point.php',
        data: {'uid': uid, 'id_pickup_drop': idPickupDrop},
      )).data,
    );
    if (!_isSuccess(res)) {
      return BoardingDropResponse(pickups: [], drops: []);
    }
    return BoardingDropResponse(
      pickups: (res['PickUpStops'] as List<dynamic>? ?? [])
          .map((p) => BoardingPoint.fromJson(p))
          .toList(),
      drops: (res['DropStops'] as List<dynamic>? ?? [])
          .map((d) => DroppingPoint.fromJson(d))
          .toList(),
    );
  }

  // ── Operators ─────────────────────────────────────────────────────
  Future<List<Operator>> getOperators() async {
    final res = _unwrap((await _dio.post('/operatorlist.php', data: {})).data);
    if (!_isSuccess(res)) return [];
    return (res['operatorlist'] as List<dynamic>? ?? [])
        .map((o) => Operator.fromJson(o))
        .toList();
  }

  // ── Register on Bus API ──────────────────────────────────────────
  Future<BusAuthResponse> registerUser({
    required String name,
    required String email,
    required String mobile,
    required String password,
    required String ccode,
  }) async {
    final res = _unwrap(
      (await _dio.post(
        '/reg_user.php',
        data: {
          'name': name,
          'email': email,
          'mobile': mobile,
          'password': password,
          'ccode': ccode,
          'user_type': 'USER',
          'skip_verification': true,
        },
      )).data,
    );
    return BusAuthResponse.fromJson(res);
  }

  // ── Login on Bus API ─────────────────────────────────────────────
  Future<BusAuthResponse> loginUser({
    required String email,
    required String password,
    String ccode = '',
  }) async {
    final data = <String, dynamic>{'mobile': email, 'password': password};
    if (ccode.isNotEmpty) data['ccode'] = ccode;
    final res = _unwrap((await _dio.post('/user_login.php', data: data)).data);
    return BusAuthResponse.fromJson(res);
  }

  // ── Book Ticket ──────────────────────────────────────────────────
  Future<BookTicketResponse> bookTicket({
    required String uid,
    required String name,
    required String busId,
    required String operatorId,
    required String email,
    required String ccode,
    required String mobile,
    required String pickupId,
    required String dropId,
    required double ticketPrice,
    required double total,
    required double couAmt,
    required double wallAmt,
    required String bookDate,
    required int totalSeat,
    required int paymentMethodId,
    required String transactionId,
    String? seatList,
    int? packageId,
    required double taxAmt,
    required String boardingCity,
    required String dropCity,
    required String busPicktime,
    required String busDroptime,
    required String diffPickDrop,
    required String subPickTime,
    required String subPickPlace,
    required String subPickAddress,
    required String subDropTime,
    required String subDropPlace,
    required String subDropAddress,
    required double subtotal,
    required String userType,
    required double commission,
    required double commPer,
    required List<PassengerPayload> passengers,
  }) async {
    final res = _unwrap(
      (await _dio.post(
        '/ticket_book.php',
        data: {
          'uid': uid,
          'name': name,
          'bus_id': busId,
          'operator_id': operatorId,
          'email': email,
          'ccode': ccode,
          'mobile': mobile,
          'pickup_id': pickupId,
          'drop_id': dropId,
          'ticket_price': ticketPrice,
          'total': total,
          'cou_amt': couAmt,
          'wall_amt': wallAmt,
          'book_date': bookDate,
          'total_seat': totalSeat,
          'payment_method_id': paymentMethodId,
          'transaction_id': transactionId,
          'seat_list': seatList ?? '',
          'package_id': packageId,
          'tax_amt': taxAmt,
          'boarding_city': boardingCity,
          'drop_city': dropCity,
          'bus_picktime': busPicktime,
          'bus_droptime': busDroptime,
          'Difference_pick_drop': diffPickDrop,
          'sub_pick_time': subPickTime,
          'sub_pick_place': subPickPlace,
          'sub_pick_address': subPickAddress,
          'sub_drop_time': subDropTime,
          'sub_drop_place': subDropPlace,
          'sub_drop_address': subDropAddress,
          'subtotal': subtotal,
          'user_type': userType,
          'commission': commission,
          'comm_per': commPer,
          'PessengerData': passengers.map((p) => p.toJson()).toList(),
        },
      )).data,
    );
    return BookTicketResponse.fromJson(res);
  }

  // ── Booking History ──────────────────────────────────────────────
  Future<List<Booking>> getBookingHistory(String uid, {String? status}) async {
    final data = <String, dynamic>{'uid': uid};
    if (status != null) data['status'] = status;
    final res = _unwrap(
      (await _dio.post('/booking_history.php', data: data)).data,
    );
    if (!_isSuccess(res)) return [];
    return (res['tickethistory'] as List<dynamic>? ?? [])
        .map((b) => Booking.fromHistory(b))
        .toList();
  }

  // ── Booking Details ──────────────────────────────────────────────
  Future<Booking?> getBookingDetails(String uid, String ticketId) async {
    final res = _unwrap(
      (await _dio.post(
        '/booking_details.php',
        data: {'uid': uid, 'ticket_id': ticketId},
      )).data,
    );
    if (!_isSuccess(res)) return null;
    final list = res['tickethistory'] as List<dynamic>? ?? [];
    if (list.isEmpty) return null;
    return Booking.fromDetails(list.first);
  }

  // ── Cancel Ticket ────────────────────────────────────────────────
  Future<bool> cancelTicket({
    required String ticketId,
    required String uid,
    required double total,
    required String reason,
  }) async {
    final res = _unwrap(
      (await _dio.post(
        '/ticket_cancle.php',
        data: {
          'ticket_id': ticketId,
          'uid': uid,
          'total': total,
          'comment_reject': reason,
        },
      )).data,
    );
    return _isSuccess(res);
  }

  // ── Check Coupon ─────────────────────────────────────────────────
  Future<Coupon?> checkCoupon({
    required String uid,
    required String couponCode,
    required double amount,
    String? operatorId,
  }) async {
    final data = <String, dynamic>{
      'uid': uid,
      'coupon_code': couponCode,
      'amount': amount,
    };
    if (operatorId != null) data['operator_id'] = operatorId;
    final res = _unwrap(
      (await _dio.post('/u_check_coupon.php', data: data)).data,
    );
    if (!_isSuccess(res)) return null;
    return Coupon.fromJson(res);
  }
}

// ── Response Wrappers ───────────────────────────────────────────────

class BusSearchResponse {
  final List<BusSearchResult> buses;
  final String currency;

  const BusSearchResponse({required this.buses, required this.currency});
}

class BoardingDropResponse {
  final List<BoardingPoint> pickups;
  final List<DroppingPoint> drops;

  const BoardingDropResponse({required this.pickups, required this.drops});
}

class BusAuthResponse {
  final bool success;
  final String message;
  final String? uid;
  final String? name;
  final String? email;
  final String? mobile;
  final String? currency;

  const BusAuthResponse({
    required this.success,
    required this.message,
    this.uid,
    this.name,
    this.email,
    this.mobile,
    this.currency,
  });

  factory BusAuthResponse.fromJson(Map<String, dynamic> json) {
    final userLogin = json['UserLogin'];
    return BusAuthResponse(
      success: json['Result']?.toString().toLowerCase() == 'true',
      message: json['ResponseMsg'] ?? '',
      uid: userLogin?['id']?.toString(),
      name: userLogin?['name']?.toString(),
      email: userLogin?['email']?.toString(),
      mobile: userLogin?['mobile']?.toString(),
      currency: json['currency']?.toString(),
    );
  }
}

class BookTicketResponse {
  final bool success;
  final String message;
  final String? wallet;

  const BookTicketResponse({
    required this.success,
    required this.message,
    this.wallet,
  });

  factory BookTicketResponse.fromJson(Map<String, dynamic> json) {
    return BookTicketResponse(
      success: json['Result']?.toString().toLowerCase() == 'true',
      message: json['ResponseMsg'] ?? '',
      wallet: json['wallet']?.toString(),
    );
  }
}

class PassengerPayload {
  final String name;
  final int age;
  final String gender;
  final String seatNo;

  const PassengerPayload({
    required this.name,
    required this.age,
    required this.gender,
    required this.seatNo,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'gender': gender,
    'seat_no': seatNo,
  };
}
