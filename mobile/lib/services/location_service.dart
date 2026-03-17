import 'package:permission_handler/permission_handler.dart';
import '../bridge/vendetta_bridge.dart';

class Position {
  final double latitude;
  final double longitude;
  final double accuracy;
  const Position({required this.latitude, required this.longitude, required this.accuracy});
}

class LocationService {
  static LocationService? _i;
  static LocationService get instance => _i ??= LocationService._();
  LocationService._();

  Position? _pos;
  bool _hasPermission = false;

  bool get hasPermission => _hasPermission;
  Position? get lastKnown => _pos;

  Future<bool> requestPermission() async {
    final s = await Permission.location.request();
    _hasPermission = s.isGranted;
    return _hasPermission;
  }

  Future<Position?> currentPosition() async {
    // TODO: real GPS via geolocator package
    _pos = const Position(latitude: 48.1372, longitude: 11.5761, accuracy: 8.0);
    return _pos;
  }

  Future<String?> currentGeohash() async {
    final pos = await currentPosition();
    if (pos == null) return null;
    return VendettaBridge.instance.encodeGeohash(pos.latitude, pos.longitude);
  }

  bool isAccuracyOk(double meters) => meters <= 150.0;
}
