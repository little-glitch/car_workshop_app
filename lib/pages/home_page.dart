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
        selectedRadius * 1000 // Convert km to meters
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

  Future<void> _openInGoogleMaps(Workshop workshop) async {
    print('Opening maps for: ${workshop.name} at ${workshop.lat}, ${workshop.lng}');
    
    // Simple Google Maps URL
    final url = 'https://www.google.com/maps/search/?api=1&query=${workshop.lat},${workshop.lng}';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open maps'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      print('Maps error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps'),
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
            // Premium Location Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF5E4B8C),
                    const Color(0xFF8A6FB0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5E4B8C).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR LOCATION',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          placeName ?? 'Getting location...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Premium Radius Selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SEARCH RADIUS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B6578),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: radiusOptions.map((radius) {
                        final isSelected = radius == selectedRadius;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: FilterChip(
                            label: Text('$radius km'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                selectedRadius = radius;
                              });
                              _fetchNearbyWorkshops();
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF5E4B8C),
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF2D2A3A),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(
                                color: isSelected ? Colors.transparent : const Color(0xFFE0DCE8),
                                width: 1.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Results Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Nearby Workshops',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2A3A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  if (!isLoadingWorkshops && workshops.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E4B8C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${workshops.length} found',
                        style: const TextStyle(
                          color: Color(0xFF5E4B8C),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Workshops List
            Expanded(
              child: _buildWorkshopsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkshopsList() {
    if (isLoadingLocation || isLoadingWorkshops) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5E4B8C)),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isLoadingLocation ? 'Getting your location...' : 'Finding premium workshops...',
              style: TextStyle(
                color: const Color(0xFF6B6578),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF5E4B8C).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Color(0xFF5E4B8C),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF4A4556),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loadLocation,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5E4B8C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (workshops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF5E4B8C).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.garage_rounded,
                size: 48,
                color: Color(0xFF5E4B8C),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No workshops found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2A3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try increasing the search radius',
              style: TextStyle(
                color: const Color(0xFF6B6578),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _fetchNearbyWorkshops,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5E4B8C),
                side: const BorderSide(color: Color(0xFF5E4B8C), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
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
    final status = workshop.statusInfo;
    
    // Determine status color and icon based on status string
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.access_time_rounded;
    
    if (status['status'] == 'open') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
    } else if (status['status'] == 'closed') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with emoji and name
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF5E4B8C).withOpacity(0.1),
                            const Color(0xFF8A6FB0).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          workshop.typeEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workshop.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF2D2A3A),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5E4B8C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              workshop.typeDisplay,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5E4B8C),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Rating and distance row
                Row(
                  children: [
                    // Rating
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB800).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFFFB800),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            workshop.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D2A3A),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Distance
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E4B8C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.navigation_rounded,
                            size: 16,
                            color: const Color(0xFF5E4B8C),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            workshop.formattedDistance,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D2A3A),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status['text'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Address with premium styling
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: const Color(0xFF6B6578),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          workshop.address,
                          style: TextStyle(
                            color: const Color(0xFF4A4556),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Phone if available
                if (workshop.phone.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F7FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 18,
                          color: const Color(0xFF5E4B8C),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          workshop.phone,
                          style: TextStyle(
                            color: const Color(0xFF5E4B8C),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Premium Open in Maps button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF5E4B8C),
                            const Color(0xFF8A6FB0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5E4B8C).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(30),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Open in Maps',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}