import 'package:flutter/foundation.dart';
import 'alchemy_service.dart';

enum VendettaTier { free, bronze, silver, gold, platinum }

extension TierInfo on VendettaTier {
  String get displayName => switch (this) {
        VendettaTier.free => 'FREE',
        VendettaTier.bronze => 'Bronze',
        VendettaTier.silver => 'Silver',
        VendettaTier.gold => 'Gold',
        VendettaTier.platinum => 'Platinum',
      };

  double get rewardMultiplier => switch (this) {
        VendettaTier.free => 0.5,
        VendettaTier.bronze => 1.0,
        VendettaTier.silver => 1.25,
        VendettaTier.gold => 1.5,
        VendettaTier.platinum => 2.0,
      };

  int get trustBoost => switch (this) {
        VendettaTier.free => 0,
        VendettaTier.bronze => 50,
        VendettaTier.silver => 100,
        VendettaTier.gold => 200,
        VendettaTier.platinum => 300,
      };

  String get minLock => switch (this) {
        VendettaTier.free => '-',
        VendettaTier.bronze => '1.000 IFR',
        VendettaTier.silver => '5.000 IFR',
        VendettaTier.gold => '10.000 IFR',
        VendettaTier.platinum => '50.000 IFR',
      };
}

class TierService {
  static TierService? _i;
  static TierService get instance => _i ??= TierService._();
  TierService._();

  VendettaTier _currentTier = VendettaTier.free;
  double _lockedIfr = 0.0;
  DateTime? _lastCheck;

  VendettaTier get currentTier => _currentTier;
  double get lockedIfr => _lockedIfr;

  /// Detect tier from on-chain IFR Lock (5-min cache)
  Future<VendettaTier> detectTier(String walletAddress) async {
    if (_lastCheck != null && DateTime.now().difference(_lastCheck!) < const Duration(minutes: 5)) {
      return _currentTier;
    }

    try {
      _lockedIfr = await AlchemyService.instance.getLockedIfrBalance(walletAddress);
      _currentTier = _tierFromAmount(_lockedIfr);
      _lastCheck = DateTime.now();
      debugPrint('Tier: ${_currentTier.displayName} ($_lockedIfr IFR locked)');
      return _currentTier;
    } catch (e) {
      debugPrint('Tier detection error: $e');
      return VendettaTier.free;
    }
  }

  VendettaTier _tierFromAmount(double ifr) {
    if (ifr >= 50000) return VendettaTier.platinum;
    if (ifr >= 10000) return VendettaTier.gold;
    if (ifr >= 5000) return VendettaTier.silver;
    if (ifr >= 1000) return VendettaTier.bronze;
    return VendettaTier.free;
  }

  int estimateCredits({required int baseTrust, required bool isFirstMover, required int dupCount}) {
    final trustMult = baseTrust / 1000.0;
    final tierMult = _currentTier.rewardMultiplier;
    final firstMult = isFirstMover ? 2.0 : 1.0;
    final dc = dupCount < 1 ? 1 : dupCount;
    return (100 * trustMult * tierMult * firstMult / dc).round();
  }

  void invalidateCache() => _lastCheck = null;
}
