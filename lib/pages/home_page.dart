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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  double? lat;
  double? lng;
  String? placeName;
  List<Workshop> workshops = [];
  bool isLoadingLocation = true;
  bool isLoadingWorkshops = false;
  String? errorMessage;
  int selectedRadius = 5;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<int> radiusOptions = [1, 2, 5, 10, 20, 30];

  // Premium color palette
  static const Color premiumGold = Color(0xFFFFD700);
  static const Color premiumPurple = Color(0xFF8B5CF6);
  static const Color premiumDeepPurple = Color(0xFF6D28D9);
  static const Color premiumCharcoal = Color(0xFF1F1F2B);
  static const Color premiumSilver = Color(0xFFE2E8F0);
  static const Color premiumRose = Color(0xFFF43F5E);
  static const Color premiumEmerald = Color(0xFF10B981);
  static const Color premiumAmber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      _animationController.forward();
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
    if (lat == null || lng == null) return;

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
          errorMessage = 'No workshops found within $selectedRadius km';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading workshops';
      });
    } finally {
      setState(() {
        isLoadingWorkshops = false;
      });
    }
  }

  Future<void> _openInGoogleMaps(Workshop workshop) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${workshop.lat},${workshop.lng}';
    
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open Google Maps'),
            backgroundColor: premiumRose,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
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
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: premiumPurple,
          secondary: premiumGold,
          tertiary: premiumEmerald,
          surface: Colors.white,
          background: const Color(0xFFFAFAFA),
          error: premiumRose,
        ),
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineMedium: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontSize: 14),
        ),
        cardTheme: CardThemeData( // Fixed: Changed from CardTheme to CardThemeData
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey.shade100,
          selectedColor: premiumPurple,
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'ELITE WORKSHOPS',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 2,
              color: premiumCharcoal,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: premiumCharcoal,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: premiumPurple),
                onPressed: _loadLocation,
                tooltip: 'Refresh location',
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Premium background gradient
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    premiumPurple.withOpacity(0.05),
                    const Color(0xFFFAFAFA),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Location Header with Glassmorphism
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              premiumPurple,
                              premiumDeepPurple,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: premiumPurple.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Location icon with glass effect
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Location text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CURRENT LOCATION',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    placeName ?? 'Getting location...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
                    ),
                  ),

                  // Premium Radius Selector
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: premiumPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.radar_rounded,
                                    color: premiumPurple,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'SEARCH RADIUS',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: premiumCharcoal,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: radiusOptions.map((radius) {
                                  final isSelected = radius == selectedRadius;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      child: ChoiceChip(
                                        label: Text(
                                          '$radius km',
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : premiumCharcoal,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() => selectedRadius = radius);
                                          _fetchNearbyWorkshops();
                                        },
                                        backgroundColor: Colors.grey.shade50,
                                        selectedColor: premiumPurple,
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                          side: BorderSide(
                                            color: isSelected ? Colors.transparent : Colors.grey.shade200,
                                            width: 1,
                                          ),
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
                    ),
                  ),

                  // Results Header with Counter
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        child: Row(
                          children: [
                            const Text(
                              'PREMIUM WORKSHOPS',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: premiumCharcoal,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const Spacer(),
                            if (!isLoadingWorkshops && workshops.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      premiumPurple.withOpacity(0.1),
                                      premiumDeepPurple.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: premiumPurple.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${workshops.length} found',
                                  style: TextStyle(
                                    color: premiumPurple,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Workshops List
                  _buildWorkshopsSliver(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkshopsSliver() {
    if (isLoadingLocation || isLoadingWorkshops) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      premiumPurple.withOpacity(0.1),
                      premiumDeepPurple.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(premiumPurple),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isLoadingLocation ? 'FINDING YOUR LOCATION' : 'DISCOVERING WORKSHOPS',
                style: TextStyle(
                  color: premiumCharcoal.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: premiumRose.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: premiumRose,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: premiumCharcoal.withOpacity(0.7),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loadLocation,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('TRY AGAIN'),
                  style: FilledButton.styleFrom(
                    backgroundColor: premiumPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (workshops.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: premiumPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.garage_rounded,
                  size: 64,
                  color: premiumPurple.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'NO WORKSHOPS FOUND',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: premiumCharcoal,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try increasing the search radius',
                style: TextStyle(
                  color: premiumCharcoal.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _fetchNearbyWorkshops,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('REFRESH'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: premiumPurple,
                  side: BorderSide(color: premiumPurple.withOpacity(0.3), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: PremiumWorkshopCard(
                workshop: workshops[index],
                onTap: () => _openInGoogleMaps(workshops[index]),
              ),
            );
          },
          childCount: workshops.length,
        ),
      ),
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

  Color _getCardGradientStart() {
    switch (workshop.workshopType) {
      case 'car_repair':
      case 'auto_repair':
        return const Color(0xFF8B5CF6); // Premium Purple
      case 'car_wash':
        return const Color(0xFF10B981); // Emerald
      case 'tyres':
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFF6D28D9); // Deep Purple
    }
  }

  Color _getCardGradientEnd() {
    switch (workshop.workshopType) {
      case 'car_repair':
      case 'auto_repair':
        return const Color(0xFF6D28D9);
      case 'car_wash':
        return const Color(0xFF059669);
      case 'tyres':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF5B21B6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = workshop.statusInfo;
    final gradientStart = _getCardGradientStart();
    final gradientEnd = _getCardGradientEnd();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.grey.shade100,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Premium type indicator
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          gradientStart.withOpacity(0.1),
                          gradientEnd.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(28),
                        bottomLeft: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          workshop.typeEmoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          workshop.typeDisplay.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: gradientStart,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Workshop name with premium badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              workshop.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xFF1F1F2B),
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Rating and distance row
                      Row(
                        children: [
                          // Rating badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Color(0xFFFFD700),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  workshop.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Color(0xFF1F1F2B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Distance badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: gradientStart.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.navigation_rounded,
                                  size: 14,
                                  color: gradientStart,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  workshop.formattedDistance,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: gradientStart,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: status['status'] == 'open'
                              ? Colors.green.withOpacity(0.1)
                              : status['status'] == 'closed'
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              status['status'] == 'open'
                                  ? Icons.check_circle_rounded
                                  : status['status'] == 'closed'
                                      ? Icons.cancel_rounded
                                      : Icons.access_time_rounded,
                              size: 14,
                              color: status['status'] == 'open'
                                  ? Colors.green
                                  : status['status'] == 'closed'
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status['text'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: status['status'] == 'open'
                                    ? Colors.green
                                    : status['status'] == 'closed'
                                        ? Colors.red
                                        : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Address with icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              workshop.address,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Phone if available
                      if (workshop.phone.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              workshop.phone,
                              style: TextStyle(
                                color: gradientStart,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Open in Maps button with premium styling
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [gradientStart, gradientEnd],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: gradientStart.withOpacity(0.3),
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
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'VIEW ON MAPS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}