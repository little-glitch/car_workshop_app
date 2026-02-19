import 'dart:math' as Math;
import 'dart:math' show Random;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/workshop.dart';

class WorkshopService {
  static const String overpassUrl = "https://overpass-api.de/api/interpreter";
  
  static Map<String, CacheEntry> _cache = {};
  
  static Future<List<Workshop>> fetchNearbyWorkshops(
      double lat, double lng, double radiusInMeters) async {
    
    // 🔴 TEST MODE: Return fake data so UI always works
    // Comment this out when you want real data
    return _getFakeWorkshops(lat, lng);
    
    // 🔵 REAL CODE (commented out for testing)
    /*
    String cacheKey = '${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}_$radiusInMeters';
    
    if (_cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (DateTime.now().difference(entry.timestamp).inHours < 1) {
        return entry.workshops;
      }
    }
    
    String query = '''
    [out:json][timeout:25];
    (
      node["shop"~"car_repair|auto_repair|car_workshop"](around:$radiusInMeters,$lat,$lng);
      way["shop"~"car_repair|auto_repair|car_workshop"](around:$radiusInMeters,$lat,$lng);
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
      print('Error: $e');
    }
    return [];
    */
  }
  
  // 🔴 TEST DATA - Remove this when going live
  static List<Workshop> _getFakeWorkshops(double userLat, double userLng) {
    return [
      Workshop(
        id: '1',
        name: 'Quick Fix Auto Repair',
        lat: userLat + 0.01,
        lng: userLng + 0.01,
        address: '123 Main Street, Downtown',
        phone: '+1 555-0123',
        openingHours: 'Mon-Fri 9am-6pm',
        rating: 4.5,
        workshopType: 'car_repair',
        distance: 1.2,
      ),
      Workshop(
        id: '2',
        name: 'Premium Car Care',
        lat: userLat - 0.008,
        lng: userLng + 0.005,
        address: '456 Oak Avenue, Uptown',
        phone: '+1 555-0456',
        openingHours: 'Mon-Sat 8am-8pm',
        rating: 4.8,
        workshopType: 'auto_repair',
        distance: 0.8,
      ),
      Workshop(
        id: '3',
        name: 'Speedy Tyres & Service',
        lat: userLat + 0.005,
        lng: userLng - 0.012,
        address: '789 Pine Road, Westside',
        phone: '+1 555-0789',
        openingHours: '24/7',
        rating: 4.2,
        workshopType: 'tyres',
        distance: 2.5,
      ),
      Workshop(
        id: '4',
        name: 'Express Car Wash',
        lat: userLat - 0.015,
        lng: userLng - 0.008,
        address: '321 River Street, Eastside',
        phone: '+1 555-0321',
        openingHours: '9am-9pm daily',
        rating: 4.3,
        workshopType: 'car_wash',
        distance: 3.1,
      ),
    ];
  }
  
  static List<Workshop> _parseWorkshops(
      Map<String, dynamic> data, double userLat, double userLng) {
    List<Workshop> workshops = [];
    
    if (data['elements'] != null) {
      for (var element in data['elements']) {
        try {
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
              
              String name = tags['name'] ?? 'Unknown Workshop';
              String address = _buildAddress(tags);
              String phone = tags['phone'] ?? tags['contact:phone'] ?? '';
              String hours = tags['opening_hours'] ?? 'Hours unknown';
              String type = tags['shop'] ?? tags['craft'] ?? 'car_repair';
              double distance = _calculateDistance(userLat, userLng, shopLat, shopLng);
              
              workshops.add(Workshop(
                id: element['id'].toString(),
                name: name,
                lat: shopLat,
                lng: shopLng,
                address: address,
                phone: phone,
                openingHours: hours,
                rating: _calculateRating(tags),
                workshopType: type,
                distance: distance,
              ));
            }
          }
        } catch (e) {
          continue;
        }
      }
    }
    
    workshops.sort((a, b) => a.distance.compareTo(b.distance));
    return workshops;
  }
  
  static String _buildAddress(Map<String, dynamic> tags) {
    if (tags['addr:street'] != null) {
      String street = tags['addr:street'];
      String number = tags['addr:housenumber'] ?? '';
      String city = tags['addr:city'] ?? '';
      if (number.isNotEmpty && city.isNotEmpty) {
        return '$number $street, $city';
      } else if (number.isNotEmpty) {
        return '$number $street';
      } else {
        return street;
      }
    }
    return 'Address not available';
  }
  
  static double _calculateRating(Map<String, dynamic> tags) {
    if (tags['rating'] != null) {
      return double.tryParse(tags['rating'].toString()) ?? 4.0;
    }
    return 4.0 + (Random().nextDouble() * 1.0);
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