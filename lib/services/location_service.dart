import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Get current GPS position (latitude & longitude)
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Convert latitude & longitude into readable place name
  static Future<String> getPlaceName(
      double latitude, double longitude) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(latitude, longitude);

    Placemark place = placemarks.first;

    final area = place.subLocality;               // eg: Myloor
    final city = place.locality;                  // eg: Thodupuzha
    final district = place.subAdministrativeArea; // eg: Idukki

    return [
      if (area != null && area.isNotEmpty) area,
      if (city != null && city.isNotEmpty) city,
      if (district != null && district.isNotEmpty) district,
    ].join(', ');
  }
}
