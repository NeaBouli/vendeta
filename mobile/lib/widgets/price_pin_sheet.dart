import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PricePinSheet extends StatelessWidget {
  final double latitude;
  final double longitude;
  const PricePinSheet({super.key, required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Preise in der Nähe',
              style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            '${latitude.toStringAsFixed(4)}°N ${longitude.toStringAsFixed(4)}°E',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('Lade Preise...', style: TextStyle(color: AppColors.muted))),
          const SizedBox(height: 20),
        ]),
      );
}
