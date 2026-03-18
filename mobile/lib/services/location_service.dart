import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../bridge/vendetta_bridge.dart';

class LocationService {
  static LocationService? _i;
  static LocationService get instance => _i ??= LocationService._();
  LocationService._();

  Position? _lastPosition;
  bool _hasPermission = false;

  bool get hasPermission => _hasPermission;
  Position? get lastKnownPosition => _lastPosition;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied');
      return false;
    }

    _hasPermission = true;
    return true;
  }

  Future<Position?> currentPosition() async {
    if (!_hasPermission) {
      final granted = await requestPermission();
      if (!granted) return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _lastPosition = pos;
      debugPrint('GPS: ${pos.latitude},${pos.longitude} ±${pos.accuracy}m');
      return pos;
    } catch (e) {
      debugPrint('GPS error: $e');
      return _lastPosition;
    }
  }

  Future<String?> currentGeohash() async {
    final pos = await currentPosition();
    if (pos == null) return null;
    return VendettaBridge.instance.encodeGeohash(pos.latitude, pos.longitude);
  }

  bool isAccuracyOk(double meters) => meters <= 150.0;

  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
}
