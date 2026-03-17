import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Wallet')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: .5)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('IFR Balance', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            SizedBox(height: 4),
            Text('0.00 IFR', style: TextStyle(color: AppColors.text, fontSize: 28, fontWeight: FontWeight.w700)),
            Divider(height: 24),
            Text('ETH Balance', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            SizedBox(height: 4),
            Text('0.0000 ETH', style: TextStyle(color: AppColors.muted, fontSize: 16)),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () {},
            icon: const Icon(Icons.download, color: AppColors.blue),
            label: const Text('Empfangen', style: TextStyle(color: AppColors.blue)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.blue), padding: const EdgeInsets.all(14)))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(onPressed: () {},
            icon: const Icon(Icons.upload, color: AppColors.muted),
            label: const Text('Senden', style: TextStyle(color: AppColors.muted)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border), padding: const EdgeInsets.all(14)))),
        ]),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {},
          icon: const Icon(Icons.swap_horiz, color: AppColors.orange),
          label: const Text('ETH ↔ IFR tauschen', style: TextStyle(color: AppColors.orange)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.orange), padding: const EdgeInsets.all(14)))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {},
          icon: const Icon(Icons.lock, color: AppColors.amber),
          label: const Text('IFR sperren für mehr Credits', style: TextStyle(color: AppColors.amber)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.amber), padding: const EdgeInsets.all(14)))),
      ]),
    ),
  );
}
