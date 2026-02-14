import 'package:flutter/material.dart';
import 'services/location_service.dart';

void main() {
  runApp(const CarWorkshopApp());
}

class CarWorkshopApp extends StatelessWidget {
  const CarWorkshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? placeName;
  double? lat;
  double? lng;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadLocation();
  }

  Future<void> loadLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      final place = await LocationService.getPlaceName(
        position.latitude,
        position.longitude,
      );

      setState(() {
        placeName = place;
        lat = position.latitude;
        lng = position.longitude;
        loading = false;
      });
    } catch (e) {
      setState(() {
        placeName = 'Location error';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Location')),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '📍 You are at',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    placeName ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lat: $lat\nLng: $lng',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}
