class Coupon {
  final int couponId;
  final String couponCode;
  final String couponVal;
  final String minAmt;

  const Coupon({
    required this.couponId,
    required this.couponCode,
    required this.couponVal,
    required this.minAmt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      couponId: int.tryParse(json['coupon_id'].toString()) ?? 0,
      couponCode: json['coupon_code'] ?? '',
      couponVal: json['coupon_val'] ?? '0',
      minAmt: json['min_amt']?.toString() ?? '0',
    );
  }

  double get discountAmount => double.tryParse(couponVal) ?? 0;
}
