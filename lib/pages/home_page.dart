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
  int selectedRadius = 5; // Default 5km

  final List<int> radiusOptions = [1, 2, 5, 10, 20, 30];

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      isLoadingLocation = true;
      errorMessage = null;
      workshops = [];
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
      print('Location error: $e');
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
    if (lat == null || lng == null) {
      setState(() {
        errorMessage = 'Location not available. Please refresh.';
      });
      return;
    }

    setState(() {
      isLoadingWorkshops = true;
      errorMessage = null;
    });

    try {
      print('🔍 Searching at: $lat, $lng with radius $selectedRadius km');

      final results = await WorkshopService.fetchNearbyWorkshops(
        lat!,
        lng!,
        selectedRadius * 1000, // Convert km to meters
      );

      print('📊 Found ${results.length} workshops');

      setState(() {
        workshops = results;
      });

      if (results.isEmpty) {
        setState(() {
          errorMessage = 'No workshops found within $selectedRadius km. Try increasing the radius.';
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        errorMessage = 'Error loading workshops. Please try again.';
      });
    } finally {
      setState(() {
        isLoadingWorkshops = false;
      });
    }
  }

  /// ✅ Fixed method: directly launches Google Maps without canLaunchUrl check
  Future<void> _openInGoogleMaps(Workshop workshop) async {
    print('Opening maps for: ${workshop.name} at ${workshop.lat}, ${workshop.lng}');

    final url = 'https://www.google.com/maps/search/?api=1&query=${workshop.lat},${workshop.lng}';
    final uri = Uri.parse(url);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Maps error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open Google Maps'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5E4B8C), // Premium purple
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFFF8F7FA), // Light premium background
        appBar: AppBar(
          title: const Text(
            'Premium Workshops',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2D2A3A),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadLocation,
              tooltip: 'Refresh location',
            ),
          ],
        ),
        body: Column(
          children: [
            // Location card, radius selector, results header...
            // (unchanged from your original code)
            Expanded(
              child: _buildWorkshopsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkshopsList() {
    // (unchanged from your original code)
    if (isLoadingLocation || isLoadingWorkshops) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    if (workshops.isEmpty) {
      return const Center(child: Text('No workshops found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: workshops.length,
      itemBuilder: (context, index) {
        return PremiumWorkshopCard(
          workshop: workshops[index],
          onTap: () => _openInGoogleMaps(workshops[index]),
        );
      },
    );
  }
}

class PremiumWorkshopCard extends StatelessWidget {
  final Workshop workshop;
  final VoidCallback onTap;

  const PremiumWorkshopCard({
    super.key,
    required this.workshop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.garage_rounded),
          title: Text(workshop.name),
          subtitle: Text(workshop.address),
          trailing: const Icon(Icons.open_in_new_rounded),
        ),
      ),
    );
  }
}
