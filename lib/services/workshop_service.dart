import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as Math;
import '../models/workshop.dart';

class WorkshopService {
  static const String overpassUrl = "https://overpass-api.de/api/interpreter";
  
  static Map<String, CacheEntry> _cache = {};
  
  static Future<List<Workshop>> fetchNearbyWorkshops(
      double lat, double lng, double radiusInMeters) async {
    
    String cacheKey = '${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}';
    if (_cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (DateTime.now().difference(entry.timestamp).inHours < 1) {
        return entry.workshops;
      }
    }
    
    String query = '''
    [out:json];
    (
      node["shop"="car_repair"](around:$radiusInMeters,$lat,$lng);
      way["shop"="car_repair"](around:$radiusInMeters,$lat,$lng);
      node["shop"="auto_repair"](around:$radiusInMeters,$lat,$lng);
      way["shop"="auto_repair"](around:$radiusInMeters,$lat,$lng);
      node["craft"="car_repair"](around:$radiusInMeters,$lat,$lng);
      way["craft"="car_repair"](around:$radiusInMeters,$lat,$lng);
    );
    out body center;
    ''';
    
    try {
      final response = await http.post(
        Uri.parse(overpassUrl),
        body: query,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final workshops = _parseWorkshops(data, lat, lng);
        
        _cache[cacheKey] = CacheEntry(
          workshops: workshops,
          timestamp: DateTime.now(),
        );
        
        return workshops;
      }
    } catch (e) {
      print('Error fetching workshops: $e');
    }
    return [];
  }
  
  static List<Workshop> _parseWorkshops(
      Map<String, dynamic> data, double userLat, double userLng) {
    List<Workshop> workshops = [];
    
    if (data['elements'] != null) {
      for (var element in data['elements']) {
        if (element['tags'] != null) {
          double? shopLat, shopLng;
          
          if (element['lat'] != null && element['lon'] != null) {
            shopLat = element['lat'];
            shopLng = element['lon'];
          } else if (element['center'] != null) {
            shopLat = element['center']['lat'];
            shopLng = element['center']['lon'];
          }
          
          if (shopLat != null && shopLng != null) {
            final tags = element['tags'];
            
            String address = _buildAddress(tags);
            String phone = tags['phone'] ?? tags['contact:phone'] ?? '';
            String hours = tags['opening_hours'] ?? 'Hours unknown';
            String type = tags['shop'] ?? tags['craft'] ?? 'car_repair';
            
            if (tags['name'] != null || address.isNotEmpty) {
              workshops.add(Workshop(
                id: element['id'].toString(),
                name: tags['name'] ?? 'Unnamed Workshop',
                lat: shopLat,
                lng: shopLng,
                address: address,
                phone: phone,
                openingHours: hours,
                rating: _calculateRating(tags),
                workshopType: type,
                distance: _calculateDistance(userLat, userLng, shopLat, shopLng),
              ));
            }
          }
        }
      }
    }
    
    workshops.sort((a, b) => a.distance.compareTo(b.distance));
    return workshops;
  }
  
  static String _buildAddress(Map<String, dynamic> tags) {
    List<String> parts = [];
    
    if (tags['addr:street'] != null) {
      String street = tags['addr:street'];
      String number = tags['addr:housenumber'] ?? '';
      parts.add('$number $street'.trim());
    }
    
    if (tags['addr:city'] != null) parts.add(tags['addr:city']);
    if (tags['addr:postcode'] != null) parts.add(tags['addr:postcode']);
    
    return parts.isNotEmpty ? parts.join(', ') : 'Address not available';
  }
  
  static double _calculateRating(Map<String, dynamic> tags) {
    if (tags['rating'] != null) {
      return double.tryParse(tags['rating'].toString()) ?? 4.0;
    }
    
    int score = 30;
    if (tags['name'] != null) score += 5;
    if (tags['phone'] != null) score += 5;
    if (tags['opening_hours'] != null) score += 5;
    
    return 1.0 + (score / 50.0) * 4.0;
  }
  
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    var dLat = _deg2rad(lat2 - lat1);
    var dLon = _deg2rad(lon2 - lon1);
    var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(_deg2rad(lat1)) * Math.cos(_deg2rad(lat2)) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  }
  
  static double _deg2rad(double deg) => deg * (Math.pi / 180.0);
}

class CacheEntry {
  final List<Workshop> workshops;
  final DateTime timestamp;
  CacheEntry({required this.workshops, required this.timestamp});
}