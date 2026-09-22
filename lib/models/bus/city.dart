class City {
  final String id;
  final String title;

  const City({required this.id, required this.title});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(id: json['id'].toString(), title: json['title'] ?? '');
  }

  @override
  String toString() => title;
}
