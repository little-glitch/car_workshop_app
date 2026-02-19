import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'workshops.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WorkshopListPage(),
    );
  }
}

class WorkshopListPage extends StatefulWidget {
  const WorkshopListPage({super.key});

  @override
  State<WorkshopListPage> createState() => _WorkshopListPageState();
}

class _WorkshopListPageState extends State<WorkshopListPage> {
  Position? userLocation;

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      userLocation = position;
    });
  }

  double getDistance(double lat, double lng) {
    if (userLocation == null) return 0;

    return Geolocator.distanceBetween(
          userLocation!.latitude,
          userLocation!.longitude,
          lat,
          lng,
        ) /
        1000;
  }

  void openMap(double lat, double lng) async {
    final url =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Workshops")),
      body: userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: workshops.length,
              itemBuilder: (context, index) {
                final w = workshops[index];
                final distance = getDistance(w.lat, w.lng);

                return Card(
                  child: ListTile(
                    title: Text(w.name),
                    subtitle: Text(
                      "⭐ ${w.rating} • ${distance.toStringAsFixed(2)} km away",
                    ),
                    trailing: const Icon(Icons.map),
                    onTap: () => openMap(w.lat, w.lng),
                  ),
                );
              },
            ),
    );
  }
}
