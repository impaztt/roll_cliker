class GameStats {
  int totalTaps;
  int totalCriticals;
  int totalUpgradesPurchased;
  int totalGoldenGuests;
  int totalRides;
  int totalSummons;
  int totalSkillUses;
  int totalBoosterUses;
  int totalComboBursts;

  GameStats({
    this.totalTaps = 0,
    this.totalCriticals = 0,
    this.totalUpgradesPurchased = 0,
    this.totalGoldenGuests = 0,
    this.totalRides = 0,
    this.totalSummons = 0,
    this.totalSkillUses = 0,
    this.totalBoosterUses = 0,
    this.totalComboBursts = 0,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'totalTaps': totalTaps,
        'totalCriticals': totalCriticals,
        'totalUpgradesPurchased': totalUpgradesPurchased,
        'totalGoldenGuests': totalGoldenGuests,
        'totalRides': totalRides,
        'totalSummons': totalSummons,
        'totalSkillUses': totalSkillUses,
        'totalBoosterUses': totalBoosterUses,
        'totalComboBursts': totalComboBursts,
      };

  factory GameStats.fromJson(Map<String, dynamic> json) => GameStats(
        totalTaps: json['totalTaps'] as int? ?? 0,
        totalCriticals: json['totalCriticals'] as int? ?? 0,
        totalUpgradesPurchased: json['totalUpgradesPurchased'] as int? ?? 0,
        totalGoldenGuests: json['totalGoldenGuests'] as int? ?? 0,
        totalRides: json['totalRides'] as int? ?? 0,
        totalSummons: json['totalSummons'] as int? ?? 0,
        totalSkillUses: json['totalSkillUses'] as int? ?? 0,
        totalBoosterUses: json['totalBoosterUses'] as int? ?? 0,
        totalComboBursts: json['totalComboBursts'] as int? ?? 0,
      );
}
