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
      final results = await WorkshopService.fetchNearbyWorkshops(
        lat!,
        lng!,
        selectedRadius * 1000,
      );

      setState(() {
        workshops = results;
      });

      if (results.isEmpty) {
        setState(() {
          errorMessage = 'No workshops found within $selectedRadius km. Try increasing the radius.';
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

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
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
          seedColor: const Color(0xFF5E4B8C),
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
      ),
      home: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text(
            'AutoCare Finder',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
          ),
          centerTitle: false,
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
            // Location card
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: const Icon(Icons.location_on_rounded, color: Colors.deepPurple),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Location',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            placeName ?? 'Getting location...',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Radius selector (horizontal scroll)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: radiusOptions.map((radius) {
                    final isSelected = radius == selectedRadius;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$radius km'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selectedRadius = radius;
                          });
                          _fetchNearbyWorkshops();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Results header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Nearby Workshops',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (!isLoadingWorkshops && workshops.isNotEmpty)
                    Chip(
                      label: Text('${workshops.length} found'),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            // Workshop list
            Expanded(child: _buildWorkshopsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkshopsList() {
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
    final status = workshop.statusInfo;
    final statusColor = status['status'] == 'open'
        ? Colors.green
        : status['status'] == 'closed'
            ? Colors.red
            : Colors.grey;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Emoji
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Text(workshop.typeEmoji, style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      workshop.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Rating + Distance
              Row(
                children: [
                  Chip(
                    avatar: const Icon(Icons.star_rounded, color: Color(0xFFFFB800)),
                    label: Text(workshop.rating.toStringAsFixed(1)),
                    backgroundColor: const Color(0xFFFFB800).withOpacity(0.1),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    avatar: const Icon(Icons.navigation_rounded, color: Color(0xFF5E4B8C)),
                    label: Text(workshop.formattedDistance),
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                ],
              ),

              const SizedBox(height: 16),


                // Rating + Distance
                Row(
                  children: [
                    Chip(
                      avatar: const Icon(Icons.star_rounded, color: Color(0xFFFFB800)),
                      label: Text(workshop.rating.toStringAsFixed(1)),
                      backgroundColor: const Color(0xFFFFB800).withOpacity(0.1),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      avatar: const Icon(Icons.navigation_rounded, color: Color(0xFF5E4B8C)),
                      label: Text(workshop.formattedDistance),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // Status
              Chip(
                avatar: Icon(
                  status['status'] == 'open'
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: statusColor,
                ),
                label: Text(status['text']),
                backgroundColor: statusColor.withOpacity(0.1),
              ),

              const SizedBox(height: 16),

              // Address
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF6B6578)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      workshop.address,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),

              // Phone (optional)
              if (workshop.phone.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF5E4B8C)),
                    const SizedBox(width: 8),
                    Text(
                      workshop.phone,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Open in Maps button
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open in Maps'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
