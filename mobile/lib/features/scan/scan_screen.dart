import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Preis scannen')),
    body: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.orange, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.qr_code_scanner, size: 64, color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        const Text('Barcode scannen', style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Scanner — Session 11', style: TextStyle(color: AppColors.muted, fontSize: 12)),
      ]),
    ),
  );
}
