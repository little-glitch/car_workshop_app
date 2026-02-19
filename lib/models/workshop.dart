class Workshop {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String address;
  final String phone;
  final String openingHours;
  final double rating;
  final String workshopType;
  final double distance;

  Workshop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
    required this.phone,
    required this.openingHours,
    required this.rating,
    required this.workshopType,
    required this.distance,
  });

  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m away';
    }
    return '${distance.toStringAsFixed(1)} km away';
  }

  String get status {
    if (openingHours.isEmpty || openingHours == 'Hours unknown') {
      return '⏰ Hours unknown';
    }
    
    var now = DateTime.now();
    var hour = now.hour;
    
    if (hour >= 9 && hour <= 17 && now.weekday <= 5) {
      return '🟢 Open now';
    } else {
      return '🔴 Closed';
    }
  }
}