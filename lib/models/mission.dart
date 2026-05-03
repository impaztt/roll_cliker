enum MissionMetric {
  tap,
  upgradePurchase,
  skillUse,
  critical,
  goldenGuest,
  summon,
  comboBurst,
  boosterUse,
  prestige,
  ride,
}

class MissionDef {
  final String id;
  final String title;
  final MissionMetric metric;
  final int target;
  final int essenceReward;
  final int prestigeReward;

  const MissionDef({
    required this.id,
    required this.title,
    required this.metric,
    required this.target,
    required this.essenceReward,
    required this.prestigeReward,
  });
}
