class BusSearchResult {
  final String busId;
  final String operatorId;
  final String busTitle;
  final String busNo;
  final String busImg;
  final String busPicktime;
  final String busDroptime;
  final String boardingCity;
  final String dropCity;
  final String idPickupDrop;
  final String differencePickDrop;
  final String ticketPrice;
  final String leftSeat;
  final int totlSeat;
  final int busAc;
  final int isSleeper;
  final String busRate;
  final String dekker;
  final int totalReview;
  final String agentCommission;
  final int bookLimit;
  final List<BusFacility> busFacilities;

  const BusSearchResult({
    required this.busId,
    required this.operatorId,
    required this.busTitle,
    required this.busNo,
    required this.busImg,
    required this.busPicktime,
    required this.busDroptime,
    required this.boardingCity,
    required this.dropCity,
    required this.idPickupDrop,
    required this.differencePickDrop,
    required this.ticketPrice,
    required this.leftSeat,
    required this.totlSeat,
    required this.busAc,
    required this.isSleeper,
    required this.busRate,
    required this.dekker,
    required this.totalReview,
    required this.agentCommission,
    required this.bookLimit,
    required this.busFacilities,
  });

  factory BusSearchResult.fromJson(Map<String, dynamic> json) {
    return BusSearchResult(
      busId: json['bus_id'].toString(),
      operatorId: json['operator_id'].toString(),
      busTitle: json['bus_title'] ?? '',
      busNo: json['bus_no'] ?? '',
      busImg: json['bus_img'] ?? '',
      busPicktime: json['bus_picktime'] ?? '',
      busDroptime: json['bus_droptime'] ?? '',
      boardingCity: json['boarding_city'] ?? '',
      dropCity: json['drop_city'] ?? '',
      idPickupDrop: json['id_pickup_drop'].toString(),
      differencePickDrop: json['Difference_pick_drop'] ?? '',
      ticketPrice: json['ticket_price'] ?? '0',
      leftSeat: json['left_seat'] ?? '0',
      totlSeat: int.tryParse(json['totl_seat'].toString()) ?? 0,
      busAc: int.tryParse(json['bus_ac'].toString()) ?? 0,
      isSleeper: int.tryParse(json['is_sleeper'].toString()) ?? 0,
      busRate: json['bus_rate'] ?? '0',
      dekker: json['decker'] ?? '',
      totalReview: int.tryParse(json['total_review'].toString()) ?? 0,
      agentCommission: json['agent_commission'] ?? '0',
      bookLimit: int.tryParse(json['book_limit'].toString()) ?? 0,
      busFacilities: (json['bus_facilities'] as List<dynamic>? ?? [])
          .map((f) => BusFacility.fromJson(f))
          .toList(),
    );
  }

  double get priceAsDouble => double.tryParse(ticketPrice) ?? 0;
  bool get isAC => busAc == 1;
  bool get isSleeperBus => isSleeper > 0;
  int get availableSeats => int.tryParse(leftSeat) ?? 0;

  /// Whether this trip has already departed based on [searchDate] and [busPicktime].
  bool isDepartedOn(DateTime searchDate) {
    try {
      final parts = busPicktime.split(':');
      if (parts.length < 2) return false;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final departure = DateTime(
        searchDate.year,
        searchDate.month,
        searchDate.day,
        hour,
        minute,
      );
      return DateTime.now().isAfter(departure);
    } catch (_) {
      return false;
    }
  }
}

class BusFacility {
  final String facilityName;
  final String facilityImg;

  const BusFacility({required this.facilityName, required this.facilityImg});

  factory BusFacility.fromJson(Map<String, dynamic> json) {
    return BusFacility(
      facilityName: json['facilityname'] ?? '',
      facilityImg: json['facilityimg'] ?? '',
    );
  }
}
