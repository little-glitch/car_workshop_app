class Workshop {
  final String name;
  final double lat;
  final double lng;
  final double rating;

  Workshop({
    required this.name,
    required this.lat,
    required this.lng,
    required this.rating,
  });
}

final List<Workshop> workshops = [
  Workshop(
    name: "Auto Care Center",
    lat: 12.9716,
    lng: 77.5946,
    rating: 4.3,
  ),
  Workshop(
    name: "Quick Fix Garage",
    lat: 12.9611,
    lng: 77.6387,
    rating: 4.1,
  ),
];
