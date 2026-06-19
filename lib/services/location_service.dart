import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationResult {
  const LocationResult({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

enum LocationFailure {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  unavailable,
}

class LocationFetchResult {
  const LocationFetchResult({this.location, this.failure});

  final LocationResult? location;
  final LocationFailure? failure;

  bool get isSuccess => location != null;
}

class LocationService {
  /// Solicita permiso de ubicación (si hace falta) y devuelve la posición actual.
  static Future<LocationFetchResult> fetchCurrentPosition() async {
    final permission = await _ensureLocationPermission();
    if (permission != null) {
      return LocationFetchResult(failure: permission);
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationFetchResult(
        failure: LocationFailure.serviceDisabled,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      return LocationFetchResult(
        location: LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (_) {
      return const LocationFetchResult(failure: LocationFailure.unavailable);
    }
  }

  static Future<LocationFailure?> _ensureLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;

    if (status.isGranted) return null;

    if (status.isPermanentlyDenied) {
      return LocationFailure.permissionDeniedForever;
    }

    status = await Permission.locationWhenInUse.request();

    if (status.isGranted) return null;
    if (status.isPermanentlyDenied) {
      return LocationFailure.permissionDeniedForever;
    }

    return LocationFailure.permissionDenied;
  }
}
