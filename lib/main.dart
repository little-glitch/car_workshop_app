import 'package:flutter/material.dart';
import 'services/location_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? placeName;
  String? lat;
  String? lng;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadLocation();
  }

  void loadLocation() async {
    final location = await LocationService.getExactLocation();
    setState(() {
      placeName = location['placeName'];
      lat = location['latitude'];
      lng = location['longitude'];
      loading = false;
    });
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
