import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/price_pin_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _locationGranted = false;
  double _radius = 5.0;

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    final status = await Permission.location.request();
    setState(() => _locationGranted = status.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        // Map placeholder — MapLibre renders here
        Container(
          color: AppColors.bg3,
          child: const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.map, size: 64, color: AppColors.muted),
              SizedBox(height: 16),
              Text('MapLibre Karte', style: TextStyle(color: AppColors.muted, fontSize: 16)),
              SizedBox(height: 4),
              Text('OpenStreetMap Tiles', style: TextStyle(color: AppColors.border, fontSize: 12)),
            ]),
          ),
        ),

        // Top: Search + Radius
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SearchBarWidget(onSearch: _onSearch),
            ),
            _RadiusSlider(value: _radius, onChanged: (v) => setState(() => _radius = v)),
          ]),
        ),

        // FAB: locate me
        Positioned(
          bottom: 24,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: AppColors.bg2,
            foregroundColor: AppColors.text,
            onPressed: _locateMe,
            child: Icon(_locationGranted ? Icons.my_location : Icons.location_disabled),
          ),
        ),
      ]),
    );
  }

  void _onSearch(String query) {
    debugPrint('Search: $query, radius: $_radius km');
  }

  void _locateMe() async {
    if (!_locationGranted) {
      await _requestLocation();
      return;
    }
    _showPriceSheet(48.1372, 11.5761);
  }

  void _showPriceSheet(double lat, double lng) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PricePinSheet(latitude: lat, longitude: lng),
    );
  }
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
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.orange,
                thumbColor: AppColors.orange,
                inactiveTrackColor: AppColors.border,
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(value: value, min: 0.5, max: 50, divisions: 99, onChanged: onChanged),
            ),
          ),
          Text(
            value < 1 ? '${(value * 1000).round()}m' : '${value.toStringAsFixed(0)}km',
            style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ]),
      );
}
