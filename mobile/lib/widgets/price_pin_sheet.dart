import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/price_pin.dart';

class PricePinSheet extends StatelessWidget {
  final PricePin pin;
  const PricePinSheet({super.key, required this.pin});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pin.priceDisplay, style: const TextStyle(color: AppColors.text, fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                if (pin.isFirstMover)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.green, width: .5),
                    ),
                    child: const Text('Erster Preis', style: TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ]),
            ),
            Column(children: [
              const Text('Trust', style: TextStyle(color: AppColors.muted, fontSize: 10)),
              const SizedBox(height: 4),
              Text(
                pin.trustScore.toString(),
                style: TextStyle(
                  color: pin.trustScore > 700 ? AppColors.green : (pin.trustScore > 400 ? AppColors.amber : AppColors.red),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
          ]),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Status: ${_statusLabel(pin.status)}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            Text(_timeAgo(pin.timestamp), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.thumb_up_outlined, color: AppColors.green, size: 16),
                label: const Text('Stimmt', style: TextStyle(color: AppColors.green)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.green, width: .5)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.thumb_down_outlined, color: AppColors.muted, size: 16),
                label: const Text('Stimmt nicht', style: TextStyle(color: AppColors.muted)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border, width: .5)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      );

  String _statusLabel(int s) => switch (s) { 1 => 'Auto-verifiziert', 2 => 'Community', 3 => 'Angefochten', _ => 'Ausstehend' };

  String _timeAgo(int ts) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts * 1000));
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'vor ${diff.inHours}h';
    return 'vor ${diff.inDays}T';
  }
}
