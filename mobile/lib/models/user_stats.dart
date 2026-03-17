class UserStats {
  final String userHash;
  final int trustScore;
  final int tierLevel;
  final int currentCredits;
  final int totalClaimed;
  final int totalSubmissions;

  const UserStats({
    required this.userHash,
    required this.trustScore,
    required this.tierLevel,
    required this.currentCredits,
    required this.totalClaimed,
    required this.totalSubmissions,
  });

  factory UserStats.empty(String hash) => UserStats(
        userHash: hash,
        trustScore: 500,
        tierLevel: 0,
        currentCredits: 0,
        totalClaimed: 0,
        totalSubmissions: 0,
      );

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
        userHash: j['id'] ?? '',
        trustScore: j['trust_score'] ?? 500,
        tierLevel: j['tier_level'] ?? 0,
        currentCredits: int.tryParse(j['current_credits']?.toString() ?? '0') ?? 0,
        totalClaimed: int.tryParse(j['total_claimed']?.toString() ?? '0') ?? 0,
        totalSubmissions: int.tryParse(j['total_submissions']?.toString() ?? '0') ?? 0,
      );

  String get tierName => switch (tierLevel) {
        1 => 'Bronze',
        2 => 'Silver',
        3 => 'Gold',
        4 => 'Platinum',
        _ => 'Free',
      };

  double get rewardMultiplier => switch (tierLevel) {
        1 => 1.0,
        2 => 1.25,
        3 => 1.5,
        4 => 2.0,
        _ => 0.5,
      };
}
