class Location {
  final double latitude;
  final double longitude;
  final String name;
  final String type; // 'pharmacy', 'hospital', 'clinic'
  final String address;
  final String phone;
  final String hours;
  final double distance; // en km

  Location({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.hours,
    required this.distance,
  });
}
