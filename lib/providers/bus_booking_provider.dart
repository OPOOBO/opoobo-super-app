import 'package:flutter/material.dart';
import '../core/bus_api_client.dart';
import '../models/bus/city.dart';
import '../models/bus/bus_search_result.dart';
import '../models/bus/bus_layout.dart';
import '../models/bus/boarding_point.dart';
import '../models/bus/booking.dart';
import '../models/bus/coupon.dart';

enum BookingStep {
  search,
  results,
  boardingPoints,
  packageSelection,
  seatMap,
  passengerInfo,
  payment,
  success,
}

class BusBookingProvider extends ChangeNotifier {
  final BusApiClient _api;

  BusBookingProvider({BusApiClient? api}) : _api = api ?? BusApiClient();

  // ── Step Management ──────────────────────────────────────────────
  BookingStep _step = BookingStep.search;
  BookingStep get step => _step;

  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  // ── Cities ───────────────────────────────────────────────────────
  List<City> _cities = [];
  List<City> get cities => _cities;

  City? _fromCity;
  City? _toCity;
  City? get fromCity => _fromCity;
  City? get toCity => _toCity;

  DateTime _departureDate = DateTime.now();
  DateTime get departureDate => _departureDate;

  int _passengers = 1;
  int get passengers => _passengers;

  // ── Search Results ───────────────────────────────────────────────
  List<BusSearchResult> _buses = [];
  List<BusSearchResult> get buses => _buses;
  String _currency = 'NGN';
  String get currency => _currency;

  BusSearchResult? _selectedBus;
  BusSearchResult? get selectedBus => _selectedBus;

  // ── Boarding / Dropping Points ───────────────────────────────────
  List<BoardingPoint> _pickupPoints = [];
  List<BoardingPoint> get pickupPoints => _pickupPoints;
  List<DroppingPoint> _dropPoints = [];
  List<DroppingPoint> get dropPoints => _dropPoints;

  BoardingPoint? _selectedPickup;
  DroppingPoint? _selectedDrop;
  BoardingPoint? get selectedPickup => _selectedPickup;
  DroppingPoint? get selectedDrop => _selectedDrop;

  // ── Package / Seats ──────────────────────────────────────────────
  BusLayout? _layout;
  BusLayout? get layout => _layout;

  BusPackage? _selectedPackage;
  BusPackage? get selectedPackage => _selectedPackage;

  final List<String> _selectedSeats = [];
  List<String> get selectedSeats => _selectedSeats;

  // ── Passengers ───────────────────────────────────────────────────
  List<PassengerInput> _passengerInputs = [];
  List<PassengerInput> get passengerInputs => _passengerInputs;

  String _contactName = '';
  String _contactEmail = '';
  String _contactPhone = '';
  String get contactName => _contactName;
  String get contactEmail => _contactEmail;
  String get contactPhone => _contactPhone;

  // ── Payment ──────────────────────────────────────────────────────
  Coupon? _appliedCoupon;
  Coupon? get appliedCoupon => _appliedCoupon;

  double _couponDiscount = 0;
  double get couponDiscount => _couponDiscount;

  // ── Confirmation ─────────────────────────────────────────────────
  BookTicketResponse? _bookingResult;
  BookTicketResponse? get bookingResult => _bookingResult;

  // ── Booking History ──────────────────────────────────────────────
  List<Booking> _bookings = [];
  List<Booking> get bookings => _bookings;
  Booking? _selectedBooking;
  Booking? get selectedBooking => _selectedBooking;

  // ── Computed ─────────────────────────────────────────────────────
  double get ticketPrice {
    if (_selectedPackage != null) return _selectedPackage!.price;
    return double.tryParse(_selectedBus?.ticketPrice ?? '0') ?? 0;
  }

  double get subtotal => ticketPrice * _passengers;
  double get totalAfterDiscount => subtotal - _couponDiscount;
  double get tax => 0; // Tax is included in price from API
  double get total => totalAfterDiscount;

  // ── Actions ──────────────────────────────────────────────────────

  void setFromCity(City city) {
    _fromCity = city;
    notifyListeners();
  }

  void setToCity(City city) {
    _toCity = city;
    notifyListeners();
  }

  void swapCities() {
    final temp = _fromCity;
    _fromCity = _toCity;
    _toCity = temp;
    notifyListeners();
  }

  void setDepartureDate(DateTime date) {
    _departureDate = date;
    notifyListeners();
  }

  void setPassengers(int count) {
    _passengers = count.clamp(1, 9);
    notifyListeners();
  }

  // ── Load Cities ──────────────────────────────────────────────────
  Future<void> loadCities() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _cities = await _api.getCityList();
    } catch (e) {
      _error = 'Failed to load cities';
    }
    _loading = false;
    notifyListeners();
  }

  // ── Search Buses ─────────────────────────────────────────────────
  Future<void> searchBuses(String uid) async {
    if (_fromCity == null || _toCity == null) {
      _error = 'Please select origin and destination';
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final dateStr =
          '${_departureDate.year}-${_departureDate.month.toString().padLeft(2, '0')}-${_departureDate.day.toString().padLeft(2, '0')}';
      final result = await _api.searchBuses(
        uid: uid,
        boardingId: _fromCity!.id,
        dropId: _toCity!.id,
        tripDate: dateStr,
      );
      // Filter out trips that have already departed (only for today's date)
      final now = DateTime.now();
      final isToday = _departureDate.year == now.year &&
          _departureDate.month == now.month &&
          _departureDate.day == now.day;
      _buses = isToday
          ? result.buses.where((b) => !b.isDepartedOn(_departureDate)).toList()
          : result.buses;
      _currency = result.currency;
      _step = BookingStep.results;
    } catch (e) {
      _error = 'Failed to search buses. Please try again.';
    }
    _loading = false;
    notifyListeners();
  }

  // ── Select Bus ───────────────────────────────────────────────────
  Future<void> selectBus(BusSearchResult bus, String uid) async {
    _selectedBus = bus;
    _loading = true;
    _error = null;
    notifyListeners();

    if (uid.isEmpty) {
      _error = 'Please link your bus account first.';
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      final result = await _api.getBoardingPoints(
        uid: uid,
        idPickupDrop: bus.idPickupDrop,
      );
      _pickupPoints = result.pickups;
      _dropPoints = result.drops;
      _step = BookingStep.boardingPoints;
    } catch (e) {
      _error = 'Failed to load boarding points';
    }
    _loading = false;
    notifyListeners();
  }

  // ── Select Boarding Points ───────────────────────────────────────
  Future<void> selectBoardingPoints({
    required BoardingPoint pickup,
    required DroppingPoint drop,
    required String uid,
  }) async {
    _selectedPickup = pickup;
    _selectedDrop = drop;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final dateStr =
          '${_departureDate.year}-${_departureDate.month.toString().padLeft(2, '0')}-${_departureDate.day.toString().padLeft(2, '0')}';
      _layout = await _api.getBusLayout(
        uid: uid,
        busId: _selectedBus!.busId,
        tripDate: dateStr,
      );
      _step = BookingStep.packageSelection;
    } catch (e) {
      _error = 'Failed to load seat layout';
    }
    _loading = false;
    notifyListeners();
  }

  // ── Select Package ───────────────────────────────────────────────
  void selectPackage(BusPackage package) {
    _selectedPackage = package;
    _selectedSeats.clear();
    if (package.allowsSeatSelection) {
      _step = BookingStep.seatMap;
    } else {
      // Economy: skip seat selection, go to passenger info
      _passengerInputs = List.generate(
        _passengers,
        (i) => PassengerInput(name: '', age: 25, gender: 'MALE', seatNo: ''),
      );
      _step = BookingStep.passengerInfo;
    }
    notifyListeners();
  }

  // ── Seat Selection ───────────────────────────────────────────────
  void toggleSeat(String seatNumber) {
    if (_selectedSeats.contains(seatNumber)) {
      _selectedSeats.remove(seatNumber);
    } else {
      if (_selectedSeats.length < _passengers) {
        _selectedSeats.add(seatNumber);
      }
    }
    notifyListeners();
  }

  void confirmSeats() {
    _passengerInputs = List.generate(
      _passengers,
      (i) => PassengerInput(
        name: '',
        age: 25,
        gender: 'MALE',
        seatNo: i < _selectedSeats.length ? _selectedSeats[i] : '',
      ),
    );
    _step = BookingStep.passengerInfo;
    notifyListeners();
  }

  // ── Passenger Info ───────────────────────────────────────────────
  void updateContactInfo({
    required String name,
    required String email,
    required String phone,
  }) {
    _contactName = name;
    _contactEmail = email;
    _contactPhone = phone;
  }

  void updatePassenger(int index, PassengerInput input) {
    if (index < _passengerInputs.length) {
      _passengerInputs[index] = input;
    }
  }

  void proceedToPayment() {
    _step = BookingStep.payment;
    notifyListeners();
  }

  // ── Coupon ───────────────────────────────────────────────────────
  Future<void> applyCoupon(String uid, String code) async {
    try {
      final coupon = await _api.checkCoupon(
        uid: uid,
        couponCode: code,
        amount: subtotal,
        operatorId: _selectedBus?.operatorId,
      );
      if (coupon != null) {
        _appliedCoupon = coupon;
        _couponDiscount = coupon.discountAmount;
        if (_couponDiscount > subtotal) _couponDiscount = subtotal;
      } else {
        _error = 'Invalid or expired coupon';
      }
    } catch (e) {
      _error = 'Failed to validate coupon';
    }
    notifyListeners();
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _couponDiscount = 0;
    notifyListeners();
  }

  // ── Book Ticket ──────────────────────────────────────────────────
  Future<bool> bookTicket(String uid) async {
    if (_selectedBus == null ||
        _selectedPickup == null ||
        _selectedDrop == null) {
      _error = 'Missing booking information';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();

    final dateStr =
        '${_departureDate.year}-${_departureDate.month.toString().padLeft(2, '0')}-${_departureDate.day.toString().padLeft(2, '0')}';

    try {
      final result = await _api.bookTicket(
        uid: uid,
        name: _contactName,
        busId: _selectedBus!.busId,
        operatorId: _selectedBus!.operatorId,
        email: _contactEmail,
        ccode: '+234',
        mobile: _contactPhone.replaceAll(RegExp(r'[^0-9]'), ''),
        pickupId: _selectedPickup!.pickId,
        dropId: _selectedDrop!.dropId,
        ticketPrice: ticketPrice,
        total: total,
        couAmt: _couponDiscount,
        wallAmt: 0,
        bookDate: dateStr,
        totalSeat: _selectedSeats.isNotEmpty
            ? _selectedSeats.length
            : _passengers,
        paymentMethodId: 1,
        transactionId: _transactionId.isNotEmpty
            ? _transactionId
            : 'TXN_FLW_${DateTime.now().millisecondsSinceEpoch}',
        seatList: _selectedSeats.isNotEmpty ? _selectedSeats.join(',') : null,
        packageId: _selectedPackage?.packageId,
        taxAmt: tax,
        boardingCity: _selectedBus!.boardingCity,
        dropCity: _selectedBus!.dropCity,
        busPicktime: _selectedBus!.busPicktime,
        busDroptime: _selectedBus!.busDroptime,
        diffPickDrop: _selectedBus!.differencePickDrop,
        subPickTime: _selectedPickup!.pickTime,
        subPickPlace: _selectedPickup!.pickPlace,
        subPickAddress: _selectedPickup!.pickAddress,
        subDropTime: _selectedDrop!.dropTime,
        subDropPlace: _selectedDrop!.dropPlace,
        subDropAddress: _selectedDrop!.dropAddress,
        subtotal: subtotal,
        userType: 'USER',
        commission: 0,
        commPer: 0,
        passengers: _passengerInputs
            .map(
              (p) => PassengerPayload(
                name: p.name,
                age: p.age,
                gender: p.gender,
                seatNo: p.seatNo,
              ),
            )
            .toList(),
      );

      _bookingResult = result;
      if (result.success) {
        _step = BookingStep.success;
      } else {
        _error = result.message;
      }
      _loading = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _error = 'Booking failed. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Payment ────────────────────────────────────────────────────────
  String _transactionId = '';
  String get transactionId => _transactionId;

  void generateTransactionId() {
    _transactionId = 'TXN_FLW_${DateTime.now().millisecondsSinceEpoch}';
    notifyListeners();
  }

  // ── Booking History ──────────────────────────────────────────────
  Future<void> loadBookingHistory(String uid, {String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _bookings = await _api.getBookingHistory(uid, status: status);
    } catch (e) {
      _error = 'Failed to load bookings';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadBookingDetails(String uid, String ticketId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedBooking = await _api.getBookingDetails(uid, ticketId);
    } catch (e) {
      _error = 'Failed to load ticket details';
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> cancelTicket(
    String uid,
    String ticketId,
    double total,
    String reason,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final success = await _api.cancelTicket(
        ticketId: ticketId,
        uid: uid,
        total: total,
        reason: reason,
      );
      if (success) {
        await loadBookingHistory(uid);
      } else {
        _error = 'Failed to cancel ticket';
      }
      _loading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Failed to cancel ticket';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Reset ────────────────────────────────────────────────────────
  void resetBooking() {
    _step = BookingStep.search;
    _selectedBus = null;
    _selectedPickup = null;
    _selectedDrop = null;
    _layout = null;
    _selectedPackage = null;
    _selectedSeats.clear();
    _passengerInputs.clear();
    _contactName = '';
    _contactEmail = '';
    _contactPhone = '';
    _appliedCoupon = null;
    _couponDiscount = 0;
    _bookingResult = null;
    _error = null;
    notifyListeners();
  }

  void goToStep(BookingStep step) {
    _step = step;
    notifyListeners();
  }
}

class PassengerInput {
  String name;
  int age;
  String gender;
  String seatNo;

  PassengerInput({
    required this.name,
    required this.age,
    required this.gender,
    required this.seatNo,
  });
}
