import 'package:flutter/material.dart';

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

class HomePage extends StatelessWidget {
  @override
Widget build(BuildContext context) {

  LocationService.getCurrentLocation().then((pos) {
    print('LAT: ${pos.latitude}, LNG: ${pos.longitude}');
  });

  return Scaffold(

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Workshops'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find help for your car, fast 🚗',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Showing workshops near your location',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: 'Search workshop or service',
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Nearest Workshops',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: const [
                  WorkshopCard(
                    name: 'SpeedFix Auto Garage',
                    distance: '0.8 km away',
                    rating: 4.6,
                  ),
                  WorkshopCard(
                    name: 'QuickCare Car Service',
                    distance: '1.2 km away',
                    rating: 4.3,
                  ),
                  WorkshopCard(
                    name: 'AutoPro Workshop',
                    distance: '2.0 km away',
                    rating: 4.8,
                  ),
                ],
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
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.car_repair,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  distance,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.amber,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(rating.toString()),
            ],
          ),
        ],
      ),
    );
  }
}
