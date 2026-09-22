class Operator {
  final String id;
  final String title;
  final String opImg;
  final String rate;
  final String address;

  const Operator({
    required this.id,
    required this.title,
    required this.opImg,
    required this.rate,
    required this.address,
  });

  factory Operator.fromJson(Map<String, dynamic> json) {
    return Operator(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      opImg: json['op_img'] ?? '',
      rate: json['rate'] ?? '0',
      address: json['address'] ?? '',
    );
  }
}
