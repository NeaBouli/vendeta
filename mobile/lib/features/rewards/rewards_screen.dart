import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/user_stats.dart';
import '../../services/graph_service.dart';

final _statsProvider = FutureProvider<UserStats>(
    (ref) => GraphService.instance.getUserStats('user_placeholder'));

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(_statsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Credits')),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)),
        error: (e, s) => _RewardsBody(stats: UserStats.empty('user_placeholder')),
        data: (s) => _RewardsBody(stats: s),
      ),
    );
  }
}

class _RewardsBody extends StatelessWidget {
  final UserStats stats;
  const _RewardsBody({required this.stats});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: .5),
            ),
            child: Column(children: [
              Text(stats.currentCredits.toString(),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.text)),
              const Text('Vendetta Credits', style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              _TierBadge(tier: stats.tierName),
              const SizedBox(height: 8),
              Text('${stats.rewardMultiplier}x Reward-Multiplier',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _StatCard(label: 'Submissions', value: stats.totalSubmissions.toString()),
            const SizedBox(width: 10),
            _StatCard(label: 'Trust', value: stats.trustScore.toString()),
            const SizedBox(width: 10),
            _StatCard(label: 'Claimed', value: stats.totalClaimed.toString()),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: stats.currentCredits >= 1000 ? () {} : null,
              style: ElevatedButton.styleFrom(disabledBackgroundColor: AppColors.bg3),
              child: Text(
                stats.currentCredits >= 1000 ? 'Als IFR auszahlen' : 'Auszahlen ab 1.000 Credits',
                style: TextStyle(color: stats.currentCredits >= 1000 ? Colors.white : AppColors.muted),
              ),
            ),
          ),
        ]),
      );
}

class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});
  Color get _color => switch (tier) { 'Bronze' => const Color(0xFFB45309), 'Silver' => const Color(0xFF64748B), 'Gold' => const Color(0xFFD97706), 'Platinum' => const Color(0xFF7C3AED), _ => AppColors.muted };
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: _color.withAlpha(25), borderRadius: BorderRadius.circular(20), border: Border.all(color: _color, width: .5)),
        child: Text(tier, style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  const _StatCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border, width: .5)),
          child: Column(children: [
            Text(value, style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          ]),
        ),
      );
}
