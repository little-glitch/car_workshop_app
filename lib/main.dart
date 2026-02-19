import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/location_service.dart';
import 'services/workshop_service.dart';
import 'models/workshop.dart';

void main() {
  runApp(const CarWorkshopApp());
}

class CarWorkshopApp extends StatelessWidget {
  const CarWorkshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nearby Car Workshops',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double? lat;
  double? lng;
  String? placeName;

  bool loading = true;
  List<Workshop> workshops = [];

  @override
  void initState() {
    super.initState();
    _loadLocationAndWorkshops();
  }

  Future<void> _loadLocationAndWorkshops() async {
    try {
      final position = await LocationService.getCurrentLocation();
      final place = await LocationService.getPlaceName(
        position.latitude,
        position.longitude,
      );

      final results = await WorkshopService.getNearbyWorkshops(
        position.latitude,
        position.longitude,
      );

      setState(() {
        lat = position.latitude;
        lng = position.longitude;
        placeName = place;
        workshops = results;
        loading = false;
      });
    } catch (e) {
      setState(() {
        placeName = 'Unable to get location';
        loading = false;
      });
    }
  }

  void _openInGoogleMaps(double lat, double lng) {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Workshops'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find help for your car, fast 🚗',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            /// 📍 TEXT LOCATION
            Text(
              placeName == null
                  ? 'Getting your location...'
                  : '📍 $placeName',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            /// 🔢 COORDINATES (optional, kept as you wanted)
            if (lat != null && lng != null)
              Text(
                'Lat: $lat , Lng: $lng',
                style: const TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 20),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : workshops.isEmpty
                      ? const Center(
                          child: Text('No workshops found nearby'),
                        )
                      : ListView.builder(
                          itemCount: workshops.length,
                          itemBuilder: (context, index) {
                            final w = workshops[index];

                            return GestureDetector(
                              onTap: () =>
                                  _openInGoogleMaps(w.lat, w.lng),
                              child: WorkshopCard(
                                name: w.name,
                                distance: 'Tap to open in Google Maps',
                                rating: 4.5,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkshopCard extends StatelessWidget {
  final String name;
  final String distance;
  final double rating;

  const WorkshopCard({
    super.key,
    required this.name,
    required this.distance,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.car_repair, color: Colors.blue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  distance,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(rating.toString()),
            ],
          ),
        ],
      ),
    );
  }
}
