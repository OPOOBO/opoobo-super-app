class BoardingPoint {
  final String pickId;
  final String pickTime;
  final String pickPlace;
  final String pickAddress;
  final String pickMobile;

  const BoardingPoint({
    required this.pickId,
    required this.pickTime,
    required this.pickPlace,
    required this.pickAddress,
    required this.pickMobile,
  });

  factory BoardingPoint.fromJson(Map<String, dynamic> json) {
    return BoardingPoint(
      pickId: json['pick_id'].toString(),
      pickTime: json['pick_time'] ?? '',
      pickPlace: json['pick_place'] ?? '',
      pickAddress: json['pick_address'] ?? '',
      pickMobile: json['pick_mobile'] ?? '',
    );
  }
}

class DroppingPoint {
  final String dropId;
  final String dropTime;
  final String dropPlace;
  final String dropAddress;
  final String dropMobile;

  const DroppingPoint({
    required this.dropId,
    required this.dropTime,
    required this.dropPlace,
    required this.dropAddress,
    required this.dropMobile,
  });

  factory DroppingPoint.fromJson(Map<String, dynamic> json) {
    return DroppingPoint(
      dropId: json['drop_id'].toString(),
      dropTime: json['drop_time'] ?? '',
      dropPlace: json['drop_place'] ?? '',
      dropAddress: json['drop_address'] ?? '',
      dropMobile: json['drop_mobile'] ?? '',
    );
  }
}
