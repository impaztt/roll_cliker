enum AchievementMetric {
  tap,
  totalCoin,
  prestige,
  goldenGuest,
  summon,
  partOwned,
  ride,
  marketTrade,
  marketDividend,
}

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final AchievementMetric metric;
  final double target;
  final int essenceReward;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.metric,
    required this.target,
    required this.essenceReward,
  });
}
