class BusLayout {
  final List<List<Seat>> lowerLayout;
  final List<List<Seat>> upperLayout;
  final String ticketPrice;
  final String dekker;
  final int totlSeat;
  final int bookLimit;
  final int isSleeper;
  final String driverDirection;
  final List<BusPackage> availablePackages;
  final String wallet;

  const BusLayout({
    required this.lowerLayout,
    required this.upperLayout,
    required this.ticketPrice,
    required this.dekker,
    required this.totlSeat,
    required this.bookLimit,
    required this.isSleeper,
    required this.driverDirection,
    required this.availablePackages,
    required this.wallet,
  });

  factory BusLayout.fromJson(Map<String, dynamic> json) {
    final layoutData =
        (json['BusLayoutData'] as List<dynamic>?)?.firstOrNull ?? {};

    return BusLayout(
      lowerLayout: _parseLayout(layoutData['lower_layout']),
      upperLayout: _parseLayout(layoutData['upper_layout']),
      ticketPrice: layoutData['ticket_price']?.toString() ?? '0',
      dekker: layoutData['decker'] ?? '',
      totlSeat: int.tryParse(layoutData['totl_seat'].toString()) ?? 0,
      bookLimit: int.tryParse(layoutData['book_limit'].toString()) ?? 0,
      isSleeper: int.tryParse(layoutData['is_sleeper'].toString()) ?? 0,
      driverDirection: layoutData['driver_direction'] ?? '',
      availablePackages: (json['available_packages'] as List<dynamic>? ?? [])
          .map((p) => BusPackage.fromJson(p))
          .toList(),
      wallet: json['wallet']?.toString() ?? '0',
    );
  }

  static List<List<Seat>> _parseLayout(dynamic layout) {
    if (layout == null) return [];
    final rows = <List<Seat>>[];
    for (final row in layout) {
      if (row is List) {
        rows.add(row.map((s) => Seat.fromJson(s)).toList());
      }
    }
    return rows;
  }

  bool get hasUpperDeck => upperLayout.isNotEmpty;
}

class Seat {
  final String seatNumber;
  final String seatType;
  final bool isBooked;
  final String? gender;
  final List<SeatPackage> reservedPackages;

  const Seat({
    required this.seatNumber,
    required this.seatType,
    required this.isBooked,
    this.gender,
    required this.reservedPackages,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      seatNumber: json['seat_number']?.toString() ?? '',
      seatType: json['seat_type']?.toString() ?? '',
      isBooked: json['is_booked'] == true || json['is_booked'] == 1,
      gender: json['gender']?.toString(),
      reservedPackages: (json['reserved_packages'] as List<dynamic>? ?? [])
          .map((p) => SeatPackage.fromJson(p))
          .toList(),
    );
  }

  bool get isAvailable => !isBooked && seatNumber.isNotEmpty;
  bool get isMale => gender == 'MALE';
  bool get isFemale => gender == 'FEMALE';
}

class SeatPackage {
  final int packageId;
  final String packageName;
  final String seatType;
  final int displayOrder;

  const SeatPackage({
    required this.packageId,
    required this.packageName,
    required this.seatType,
    required this.displayOrder,
  });

  factory SeatPackage.fromJson(Map<String, dynamic> json) {
    return SeatPackage(
      packageId: int.tryParse(json['package_id'].toString()) ?? 0,
      packageName: json['package_name'] ?? '',
      seatType: json['seat_type'] ?? '',
      displayOrder: int.tryParse(json['display_order'].toString()) ?? 0,
    );
  }
}

class BusPackage {
  final int packageId;
  final String name;
  final String description;
  final double price;
  final int remainingSeats;
  final String luggageLimit;
  final bool allowsSeatSelection;
  final bool allowsReschedule;
  final double rescheduleFee;
  final int displayOrder;

  const BusPackage({
    required this.packageId,
    required this.name,
    required this.description,
    required this.price,
    required this.remainingSeats,
    required this.luggageLimit,
    required this.allowsSeatSelection,
    required this.allowsReschedule,
    required this.rescheduleFee,
    required this.displayOrder,
  });

  factory BusPackage.fromJson(Map<String, dynamic> json) {
    return BusPackage(
      packageId: int.tryParse(json['package_id'].toString()) ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      remainingSeats: int.tryParse(json['remaining_seats'].toString()) ?? 0,
      luggageLimit: json['luggage_limit']?.toString() ?? '0',
      allowsSeatSelection:
          json['allows_seat_selection'] == 1 ||
          json['allows_seat_selection'] == true,
      allowsReschedule:
          json['allows_reschedule'] == 1 || json['allows_reschedule'] == true,
      rescheduleFee: double.tryParse(json['reschedule_fee'].toString()) ?? 0,
      displayOrder: int.tryParse(json['display_order'].toString()) ?? 0,
    );
  }
}
