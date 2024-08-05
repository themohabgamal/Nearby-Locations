import 'package:google_maps_flutter/google_maps_flutter.dart';

class Restaurant {
  final String id;
  final LatLng position;
  final String name;

  Restaurant({
    required this.id,
    required this.position,
    required this.name,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final lat = json['lat']?.toDouble() ?? 0.0;
    final lon = json['lon']?.toDouble() ?? 0.0;
    final position = LatLng(lat, lon);
    final name = json['tags']['name'] ?? 'Unnamed Restaurant';

    return Restaurant(
      id: id,
      position: position,
      name: name,
    );
  }
}
