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
      return '${(distance * 1000).toStringAsFixed(0)}m';
    }
    return '${distance.toStringAsFixed(1)}km';
  }

  String get distanceText {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} meters away';
    }
    return '${distance.toStringAsFixed(1)} km away';
  }

  // Return status info as strings/booleans instead of Colors/Icons
  Map<String, dynamic> get statusInfo {
    if (openingHours.isEmpty || openingHours == 'Hours unknown') {
      return {
        'text': 'Hours unknown',
        'status': 'unknown', // 'open', 'closed', or 'unknown'
      };
    }
    
    var now = DateTime.now();
    var hour = now.hour;
    var weekday = now.weekday;
    
    // Simple check - most shops open 9am-6pm Mon-Sat
    bool isOpen = (hour >= 9 && hour <= 18) && weekday <= 6;
    
    return {
      'text': isOpen ? 'Open now' : 'Closed',
      'status': isOpen ? 'open' : 'closed',
    };
  }

  String get typeDisplay {
    switch (workshopType) {
      case 'car_repair':
        return 'Repair Shop';
      case 'auto_repair':
        return 'Auto Repair';
      case 'car_wash':
        return 'Car Wash';
      case 'tyres':
        return 'Tyre Shop';
      default:
        return 'Workshop';
    }
  }

  // Return emoji instead of IconData for model
  String get typeEmoji {
    switch (workshopType) {
      case 'car_repair':
      case 'auto_repair':
        return '🔧';
      case 'car_wash':
        return '🧼';
      case 'tyres':
        return '⚙️';
      default:
        return '🔨';
    }
  }
}