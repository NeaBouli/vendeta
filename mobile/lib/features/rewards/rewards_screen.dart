import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Credits')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: .5)),
          child: Column(children: [
            const Text('0', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.text)),
            const Text('Vendetta Credits', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.bg3, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border)),
              child: const Text('FREE Tier', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(disabledBackgroundColor: AppColors.bg3),
            child: const Text('Auszahlen (ab 1.000 Credits)', style: TextStyle(color: AppColors.muted)),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Scanne Preise um Credits zu verdienen', style: TextStyle(color: AppColors.muted, fontSize: 12)),
      ]),
    ),
  );
}
