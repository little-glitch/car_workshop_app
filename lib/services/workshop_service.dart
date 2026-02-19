import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workshop.dart';

class WorkshopService {
  static Future<List<Workshop>> getNearbyWorkshops(
    double lat,
    double lng,
  ) async {
    final query = '''
[out:json];
node["shop"="car_repair"](around:5000,$lat,$lng);
out;
''';

    final response = await http.post(
      Uri.parse('https://overpass-api.de/api/interpreter'),
      body: {'data': query},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load workshops");
    }

    final data = jsonDecode(response.body);
    final List elements = data['elements'];

    return elements.map((e) {
      return Workshop(
        name: e['tags']?['name'] ?? 'Car Workshop',
        lat: (e['lat'] as num).toDouble(),
        lng: (e['lon'] as num).toDouble(),
        rating: 4.0, // default rating (OSM doesn’t provide ratings)
      );
    }).toList();
  }
}
