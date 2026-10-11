class Rider {
  final int id;
  final String name;
  final double latitude;
  final double longitude;

  Rider({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'],
      name: json['name'] ?? 'Unknown Rider',
      latitude:
          double.tryParse(
                json['latitude'].toString(),
              ) ??
              0,
      longitude:
          double.tryParse(
                json['longitude'].toString(),
              ) ??
              0,
    );
  }
}