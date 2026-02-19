import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import '../models/workshop.dart';

class WorkshopService {
  static const String overpassUrl = "https://overpass-api.de/api/interpreter";
  
  static Map<String, CacheEntry> _cache = {};
  
  static Future<List<Workshop>> fetchNearbyWorkshops(
      double lat, double lng, double radiusInMeters) async {
    
    String cacheKey = '${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}_$radiusInMeters';
    if (_cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (DateTime.now().difference(entry.timestamp).inHours < 1) {
        print('Returning cached workshops: ${entry.workshops.length}');
        return entry.workshops;
      }
    }
    
    // Expanded query to catch more workshop types
    String query = '''
    [out:json][timeout:25];
    (
      // Car repair shops
      node["shop"="car_repair"](around:$radiusInMeters,$lat,$lng);
      way["shop"="car_repair"](around:$radiusInMeters,$lat,$lng);
      
      // Auto repair shops
      node["shop"="auto_repair"](around:$radiusInMeters,$lat,$lng);
      way["shop"="auto_repair"](around:$radiusInMeters,$lat,$lng);
      
      // Mechanics
      node["craft"="car_repair"](around:$radiusInMeters,$lat,$lng);
      way["craft"="car_repair"](around:$radiusInMeters,$lat,$lng);
      
      // Car workshops
      node["shop"="car_workshop"](around:$radiusInMeters,$lat,$lng);
      way["shop"="car_workshop"](around:$radiusInMeters,$lat,$lng);
      
      // Tyre shops
      node["shop"="tyres"](around:$radiusInMeters,$lat,$lng);
      way["shop"="tyres"](around:$radiusInMeters,$lat,$lng);
      
      // Car washes (sometimes combined with repair)
      node["amenity"="car_wash"](around:$radiusInMeters,$lat,$lng);
      way["amenity"="car_wash"](around:$radiusInMeters,$lat,$lng);
      
      // Garages
      node["building"="garage"](around:$radiusInMeters,$lat,$lng);
      way["building"="garage"](around:$radiusInMeters,$lat,$lng);
    );
    out body center qt;
    ''';
    
    try {
      print('Fetching workshops from Overpass API...');
      final response = await http.post(
        Uri.parse(overpassUrl),
        body: query,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response: ${data['elements']?.length} elements found');
        
        final workshops = _parseWorkshops(data, lat, lng);
        print('Parsed ${workshops.length} valid workshops');
        
        _cache[cacheKey] = CacheEntry(
          workshops: workshops,
          timestamp: DateTime.now(),
        );
        
        return workshops;
      } else {
        print('API Error: ${response.statusCode}');
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
        try {
          if (element['tags'] != null) {
            double? shopLat, shopLng;
            
            // Get coordinates
            if (element['lat'] != null && element['lon'] != null) {
              shopLat = element['lat'];
              shopLng = element['lon'];
            } else if (element['center'] != null) {
              shopLat = element['center']['lat'];
              shopLng = element['center']['lon'];
            } else if (element['bounds'] != null) {
              // Approximate from bounds
              var bounds = element['bounds'];
              shopLat = (bounds['minlat'] + bounds['maxlat']) / 2;
              shopLng = (bounds['minlon'] + bounds['maxlon']) / 2;
            }
            
            if (shopLat != null && shopLng != null) {
              final tags = element['tags'];
              
              // Skip if it's clearly not a workshop
              if (tags['shop'] == 'vacant' || tags['shop'] == 'empty') {
                continue;
              }
              
              // Calculate distance
              double distance = _calculateDistance(userLat, userLng, shopLat, shopLng);
              
              // Only include if within radius (add 10% buffer)
              // if (distance > radiusInMeters/1000 * 1.1) continue;
              
              String name = tags['name'] ?? 
                          tags['brand'] ?? 
                          _generateName(tags) ?? 
                          'Car Workshop';
              
              String address = _buildAddress(tags);
              String phone = tags['phone'] ?? 
                            tags['contact:phone'] ?? 
                            tags['mobile'] ?? 
                            '';
              String hours = tags['opening_hours'] ?? 
                           tags['service_times'] ?? 
                           'Hours unknown';
              
              // Determine workshop type
              String type = tags['shop'] ?? 
                           tags['craft'] ?? 
                           tags['amenity'] ?? 
                           'car_repair';
              
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
          print('Error parsing element: $e');
          continue;
        }
      }
    }
    
    // Remove duplicates (same name and close coordinates)
    workshops = _removeDuplicates(workshops);
    
    // Sort by distance
    workshops.sort((a, b) => a.distance.compareTo(b.distance));
    
    return workshops;
  }
  
  static String _generateName(Map<String, dynamic> tags) {
    if (tags['shop'] != null) {
      return '${tags['shop'].toString().replaceAll('_', ' ').toUpperCase()} Shop';
    }
    if (tags['craft'] != null) {
      return '${tags['craft'].toString().replaceAll('_', ' ').toUpperCase()}';
    }
    return 'Car Workshop';
  }
  
  static String _buildAddress(Map<String, dynamic> tags) {
    List<String> parts = [];
    
    // Try different address formats
    if (tags['addr:street'] != null) {
      String street = tags['addr:street'];
      String number = tags['addr:housenumber'] ?? '';
      if (number.isNotEmpty) {
        parts.add('$number $street');
      } else {
        parts.add(street);
      }
    }
    
    if (tags['addr:city'] != null) {
      parts.add(tags['addr:city']);
    }
    
    if (parts.isEmpty) {
      // Try other address fields
      if (tags['address'] != null) {
        return tags['address'];
      }
      if (tags['display_name'] != null) {
        return tags['display_name'].split(',').take(3).join(',');
      }
      return 'Address not available';
    }
    
    return parts.join(', ');
  }
  
  static double _calculateRating(Map<String, dynamic> tags) {
    // Try to get actual rating
    if (tags['rating'] != null) {
      return double.tryParse(tags['rating'].toString()) ?? 4.0;
    }
    
    if (tags['reviews'] != null) {
      return double.tryParse(tags['reviews'].toString()) ?? 4.0;
    }
    
    // Generate based on data completeness (3.5-5.0 range)
    int completeness = 0;
    if (tags['name'] != null && tags['name'].toString().length > 3) completeness += 2;
    if (tags['phone'] != null) completeness += 2;
    if (tags['opening_hours'] != null) completeness += 2;
    if (tags['website'] != null) completeness += 1;
    if (tags['email'] != null) completeness += 1;
    
    // Convert to 3.5-5.0 range
    return 3.5 + (completeness / 8.0) * 1.5;
  }
  
  static List<Workshop> _removeDuplicates(List<Workshop> workshops) {
    Map<String, Workshop> unique = {};
    
    for (var w in workshops) {
      String key = '${w.name}_${w.lat.toStringAsFixed(4)}_${w.lng.toStringAsFixed(4)}';
      if (!unique.containsKey(key)) {
        unique[key] = w;
      }
    }
    
    return unique.values.toList();
  }
  
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth's radius in km
    var dLat = _deg2rad(lat2 - lat1);
    var dLon = _deg2rad(lon2 - lon1);
    var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(_deg2rad(lat1)) * Math.cos(_deg2rad(lat2)) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c; // Returns distance in km
  }
  
  static double _deg2rad(double deg) => deg * (Math.pi / 180.0);
}

class CacheEntry {
  final List<Workshop> workshops;
  final DateTime timestamp;
  CacheEntry({required this.workshops, required this.timestamp});
}