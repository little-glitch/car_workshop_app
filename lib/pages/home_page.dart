import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';
import '../services/workshop_service.dart';
import '../models/workshop.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double? lat;
  double? lng;
  String? placeName;
  List<Workshop> workshops = [];
  bool isLoadingLocation = true;
  bool isLoadingWorkshops = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      isLoadingLocation = true;
      errorMessage = null;
    });
    
    try {
      final position = await LocationService.getCurrentLocation();
      final place = await LocationService.getPlaceName(
        position.latitude,
        position.longitude,
      );
      
      setState(() {
        lat = position.latitude;
        lng = position.longitude;
        placeName = place;
      });
      
      await _fetchNearbyWorkshops();
      
    } catch (e) {
      setState(() {
        errorMessage = 'Unable to get location. Please enable location services.';
      });
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }
  
  Future<void> _fetchNearbyWorkshops() async {
    if (lat == null || lng == null) return;
    
    setState(() {
      isLoadingWorkshops = true;
      errorMessage = null;
    });
    
    try {
      final results = await WorkshopService.fetchNearbyWorkshops(
        lat!, 
        lng!, 
        5000
      );
      
      setState(() {
        workshops = results;
      });
      
      if (results.isEmpty) {
        setState(() {
          errorMessage = 'No workshops found in your area.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading workshops. Please try again.';
      });
    } finally {
      setState(() {
        isLoadingWorkshops = false;
      });
    }
  }

  Future<void> _openInGoogleMaps(Workshop workshop) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${workshop.lat},${workshop.lng}';
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Car Workshops'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLocation,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      placeName ?? 'Getting location...',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Nearby Workshops ${workshops.isNotEmpty ? '(${workshops.length})' : ''}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoadingLocation || isLoadingWorkshops) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadLocation,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (workshops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.garage_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No workshops found nearby'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchNearbyWorkshops,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: workshops.length,
      itemBuilder: (context, index) {
        return WorkshopCard(
          workshop: workshops[index],
          onTap: () => _openInGoogleMaps(workshops[index]),
        );
      },
    );
  }
}

class WorkshopCard extends StatelessWidget {
  final Workshop workshop;
  final VoidCallback onTap;

  const WorkshopCard({super.key, required this.workshop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workshop.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  Text(' ${workshop.rating.toStringAsFixed(1)}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.directions_car, size: 16, color: Colors.grey),
                  Text(' ${workshop.formattedDistance}'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                workshop.address,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              if (workshop.phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('📞 ${workshop.phone}', style: const TextStyle(fontSize: 13)),
              ],
              const SizedBox(height: 8),
              Text(
                workshop.status,
                style: TextStyle(
                  color: workshop.status.contains('Open') ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
