import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationUtils {
  static Future<bool> requestLocationPermission() async {
    final status = await Geolocator.requestPermission();
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  static LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  static bool isWithinRadius(
    Position position,
    double targetLat,
    double targetLon,
    double radiusInMeters,
  ) {
    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      targetLat,
      targetLon,
    );
    return distance <= radiusInMeters;
  }

  static String formatCoordinate(double value) {
    return value.toStringAsFixed(6);
  }

  static String formatCoordinates(double lat, double lon) {
    return '${formatCoordinate(lat)}, ${formatCoordinate(lon)}';
  }
}
