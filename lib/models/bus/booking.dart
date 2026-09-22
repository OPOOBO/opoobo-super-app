class Booking {
  final String ticketId;
  final String busName;
  final String busNo;
  final String busImg;
  final int isAc;
  final String subtotal;
  final String bookDate;
  final String ticketPrice;
  final String boardingCity;
  final String dropCity;
  final String busPicktime;
  final String busDroptime;
  final String differencePickDrop;
  final String passengerNames;
  final String qrCode;
  final String bookingStatus;

  // Extended fields from booking_details
  final int? totalSeat;
  final String? couAmt;
  final String? wallAmt;
  final String? total;
  final String? tax;
  final String? taxAmt;
  final String? transactionId;
  final String? pMethodName;
  final String? contactName;
  final String? contactEmail;
  final String? contactMobile;
  final String? subPickTime;
  final String? subPickPlace;
  final String? subPickAddress;
  final String? subPickMobile;
  final String? subDropTime;
  final String? subDropPlace;
  final String? subDropAddress;
  final int? cancleShow;
  final int? busId;
  final List<PassengerDetail>? passengers;

  const Booking({
    required this.ticketId,
    required this.busName,
    required this.busNo,
    required this.busImg,
    required this.isAc,
    required this.subtotal,
    required this.bookDate,
    required this.ticketPrice,
    required this.boardingCity,
    required this.dropCity,
    required this.busPicktime,
    required this.busDroptime,
    required this.differencePickDrop,
    required this.passengerNames,
    required this.qrCode,
    required this.bookingStatus,
    this.totalSeat,
    this.couAmt,
    this.wallAmt,
    this.total,
    this.tax,
    this.taxAmt,
    this.transactionId,
    this.pMethodName,
    this.contactName,
    this.contactEmail,
    this.contactMobile,
    this.subPickTime,
    this.subPickPlace,
    this.subPickAddress,
    this.subPickMobile,
    this.subDropTime,
    this.subDropPlace,
    this.subDropAddress,
    this.cancleShow,
    this.busId,
    this.passengers,
  });

  factory Booking.fromHistory(Map<String, dynamic> json) {
    return Booking(
      ticketId: json['ticket_id'].toString(),
      busName: json['bus_name'] ?? '',
      busNo: json['bus_no'] ?? '',
      busImg: json['bus_img'] ?? '',
      isAc: int.tryParse(json['is_ac'].toString()) ?? 0,
      subtotal: json['subtotal']?.toString() ?? '0',
      bookDate: json['book_date'] ?? '',
      ticketPrice: json['ticket_price']?.toString() ?? '0',
      boardingCity: json['boarding_city'] ?? '',
      dropCity: json['drop_city'] ?? '',
      busPicktime: json['bus_picktime'] ?? '',
      busDroptime: json['bus_droptime'] ?? '',
      differencePickDrop: json['Difference_pick_drop'] ?? '',
      passengerNames: json['passenger_names'] ?? '',
      qrCode: json['qrcode'] ?? '',
      bookingStatus: json['booking_status'] ?? '',
    );
  }

  factory Booking.fromDetails(Map<String, dynamic> json) {
    return Booking(
      ticketId: json['ticket_id'].toString(),
      busName: json['bus_name'] ?? '',
      busNo: json['bus_no'] ?? '',
      busImg: json['bus_img'] ?? '',
      isAc: int.tryParse(json['is_ac'].toString()) ?? 0,
      subtotal: json['subtotal']?.toString() ?? '0',
      bookDate: json['book_date'] ?? '',
      ticketPrice: json['ticket_price']?.toString() ?? '0',
      boardingCity: json['boarding_city'] ?? '',
      dropCity: json['drop_city'] ?? '',
      busPicktime: json['bus_picktime'] ?? '',
      busDroptime: json['bus_droptime'] ?? '',
      differencePickDrop: json['Difference_pick_drop'] ?? '',
      passengerNames: json['passenger_names'] ?? '',
      qrCode: json['qrcode'] ?? '',
      bookingStatus: json['booking_status'] ?? 'Pending',
      totalSeat: int.tryParse(json['total_seat'].toString()),
      couAmt: json['cou_amt']?.toString(),
      wallAmt: json['wall_amt']?.toString(),
      total: json['total']?.toString(),
      tax: json['tax']?.toString(),
      taxAmt: json['tax_amt']?.toString(),
      transactionId: json['transaction_id']?.toString(),
      pMethodName: json['p_method_name']?.toString(),
      contactName: json['contact_name']?.toString(),
      contactEmail: json['contact_email']?.toString(),
      contactMobile: json['contact_mobile']?.toString(),
      subPickTime: json['sub_pick_time']?.toString(),
      subPickPlace: json['sub_pick_place']?.toString(),
      subPickAddress: json['sub_pick_address']?.toString(),
      subPickMobile: json['sub_pick_mobile']?.toString(),
      subDropTime: json['sub_drop_time']?.toString(),
      subDropPlace: json['sub_drop_place']?.toString(),
      subDropAddress: json['sub_drop_address']?.toString(),
      cancleShow: int.tryParse(json['cancle_show'].toString()),
      busId: int.tryParse(json['bus_id'].toString()),
      passengers: (json['Order_Product_Data'] as List<dynamic>?)
          ?.map((p) => PassengerDetail.fromJson(p))
          .toList(),
    );
  }

  bool get isPending => bookingStatus == 'Pending';
  bool get isConfirmed => bookingStatus == 'Completed';
  bool get isCancelled => bookingStatus == 'Cancelled';
}

class PassengerDetail {
  final String name;
  final int age;
  final String gender;
  final String seatNo;

  const PassengerDetail({
    required this.name,
    required this.age,
    required this.gender,
    required this.seatNo,
  });

  factory PassengerDetail.fromJson(Map<String, dynamic> json) {
    return PassengerDetail(
      name: json['name'] ?? '',
      age: int.tryParse(json['age'].toString()) ?? 0,
      gender: json['gender'] ?? '',
      seatNo: json['seat_no'] ?? '',
    );
  }
}
