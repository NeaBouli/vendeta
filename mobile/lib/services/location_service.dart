import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static LocationService? _i;
  static LocationService get instance => _i ??= LocationService._();
  LocationService._();

  double? _lat;
  double? _lng;
  bool _hasPermission = false;

  bool get hasPermission => _hasPermission;
  double? get latitude => _lat;
  double? get longitude => _lng;

  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    _hasPermission = status.isGranted;
    return _hasPermission;
  }

  Future<void> updateLocation(double lat, double lng) async {
    _lat = lat;
    _lng = lng;
    debugPrint('Location updated: $lat, $lng');
  }
}
