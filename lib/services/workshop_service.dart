import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workshop.dart';

class WorkshopService {
  static Future<List<Workshop>> getNearbyWorkshops(
      double lat, double lng) async {
    final query = '''
[out:json];
node["shop"="car_repair"](around:5000,$lat,$lng);
out;
''';

    final response = await http.post(
      Uri.parse('https://overpass-api.de/api/interpreter'),
      body: {'data': query},
    );

    final data = jsonDecode(response.body);
    final List elements = data['elements'];

    return elements.map((e) {
      return Workshop(
        name: e['tags']?['name'] ?? 'Car Workshop',
        lat: e['lat'],
        lng: e['lon'],
      );
    }).toList();
  }
}
