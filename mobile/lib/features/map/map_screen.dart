import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('VENDETTA'),
      actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
    ),
    body: const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.map, size: 64, color: AppColors.muted),
        SizedBox(height: 16),
        Text('Karte wird geladen...', style: TextStyle(color: AppColors.muted)),
        SizedBox(height: 8),
        Text('MapLibre — Session 11', style: TextStyle(color: AppColors.border, fontSize: 12)),
      ]),
    ),
    floatingActionButton: FloatingActionButton(
      backgroundColor: AppColors.orange, foregroundColor: Colors.white,
      onPressed: () {}, child: const Icon(Icons.my_location),
    ),
  );
}
