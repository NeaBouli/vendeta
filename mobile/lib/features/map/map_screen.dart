import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_theme.dart';
import '../../models/price_pin.dart';
import '../../bridge/vendetta_bridge.dart';
import '../../services/location_service.dart';
import '../../services/graph_service.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/price_pin_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapCtrl = MapController();
  bool _locationGranted = false;
  double _radius = 5.0;
  List<PricePin> _pins = [];
  bool _loading = false;

  static const _munich = LatLng(48.1372, 11.5761);

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    final granted = await LocationService.instance.requestPermission();
    setState(() => _locationGranted = granted);
    if (granted) {
      final pos = await LocationService.instance.currentPosition();
      if (pos != null && mounted) {
        _mapCtrl.move(LatLng(pos.latitude, pos.longitude), 14);
      }
    }
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    setState(() => _loading = true);
    try {
      var geo = await LocationService.instance.currentGeohash();
      if (geo == null) {
        // Fallback: use map center
        final center = _mapCtrl.camera.center;
        geo = await VendettaBridge.instance.encodeGeohash(center.latitude, center.longitude);
      }
      final pins = await GraphService.instance.nearbyPrices(geohash: geo, currency: 'EUR');
      if (mounted) setState(() => _pins = pins);
    } catch (e) {
      debugPrint('Load prices: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(initialCenter: _munich, initialZoom: 13),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.vendetta.app',
              maxZoom: 18,
            ),
            MarkerLayer(
              markers: _pins
                  .map((p) => Marker(
                        point: LatLng(p.latitude, p.longitude),
                        width: 70,
                        height: 32,
                        child: GestureDetector(
                          onTap: () => _showPin(p),
                          child: _PriceMarker(pin: p),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        SafeArea(
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(12), child: SearchBarWidget(onSearch: _onSearch)),
            _RadiusSlider(value: _radius, onChanged: (v) => setState(() => _radius = v)),
          ]),
        ),
        if (_loading)
          const Positioned(
            top: 120,
            right: 16,
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange)),
          ),
        if (LocationService.instance.lastKnownPosition != null)
          Positioned(
            top: 130,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bg2.withAlpha(230),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: .5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.gps_fixed, size: 10,
                    color: _accuracyColor(LocationService.instance.lastKnownPosition!.accuracy)),
                const SizedBox(width: 4),
                Text('±${LocationService.instance.lastKnownPosition!.accuracy.round()}m',
                    style: const TextStyle(color: AppColors.text, fontSize: 9)),
              ]),
            ),
          ),
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton.small(
            backgroundColor: AppColors.bg2,
            foregroundColor: AppColors.text,
            onPressed: _locateMe,
            child: Icon(_locationGranted ? Icons.my_location : Icons.location_disabled, size: 20),
          ),
        ),
      ]),
    );
  }

  void _onSearch(String q) {
    debugPrint('Search: $q');
    _loadPrices();
  }

  Future<void> _locateMe() async {
    if (!_locationGranted) {
      await _requestLocation();
      return;
    }
    final pos = await LocationService.instance.currentPosition();
    if (pos != null && mounted) {
      _mapCtrl.move(LatLng(pos.latitude, pos.longitude), 15);
      setState(() {}); // refresh accuracy badge
      _loadPrices();
    }
  }

  Color _accuracyColor(double meters) {
    if (meters <= 20) return AppColors.green;
    if (meters <= 50) return AppColors.amber;
    if (meters <= 150) return AppColors.orange;
    return AppColors.red;
  }

  void _showPin(PricePin pin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => PricePinSheet(pin: pin),
    );
  }
}

class _PriceMarker extends StatelessWidget {
  final PricePin pin;
  const _PriceMarker({required this.pin});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: pin.isFirstMover ? AppColors.green : AppColors.bg2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: pin.isFirstMover ? AppColors.green : AppColors.border),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Text(
          '${(pin.priceCents / 100).toStringAsFixed(2)}\u20AC',
          style: TextStyle(
            color: pin.isFirstMover ? Colors.white : AppColors.text,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _RadiusSlider extends StatelessWidget {
  final double value;
  final void Function(double) onChanged;
  const _RadiusSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: .5),
        ),
        child: Row(children: [
          const Icon(Icons.radar, color: AppColors.muted, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Slider(
              value: value, min: 0.5, max: 50, divisions: 99,
              activeColor: AppColors.orange, inactiveColor: AppColors.border,
              onChanged: onChanged,
            ),
          ),
          Text(
            value < 1 ? '${(value * 1000).round()}m' : '${value.toStringAsFixed(0)}km',
            style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ]),
      );
}
