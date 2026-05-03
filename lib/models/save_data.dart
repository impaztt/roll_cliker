import 'booster.dart';
import 'game_stats.dart';
import 'stock_market.dart';

class SaveData {
  static const currentVersion = 1;

  int version;
  double coin;
  double totalCoinEarned;
  double purchasedCoinUnconverted;

  Map<String, int> tapUpgradeLevels;
  Map<String, int> autoProducerLevels;
  Map<String, int> prestigeUpgradeLevels;

  int parkEssence;
  int prestigePoints;
  int prestigeCount;

  Map<String, int> ownedParts; // partId -> count
  Set<String> unlockedAchievements;
  Set<String> unlockedFeatures;

  StockMarketState market;

  int totalTaps;
  int tapsSinceGoldenGuest;
  int currentCombo;
  DateTime? lastTapAt;

  List<ActiveBooster> activeBoosters;
  Map<String, DateTime> skillReadyAt;

  // Mission tracking
  int dailyMissionDayKey;
  int weeklyMissionWeekKey;
  Map<String, int> dailyMissionProgress;
  Set<String> dailyMissionClaimed;
  Map<String, int> weeklyMissionProgress;
  Set<String> weeklyMissionClaimed;

  int summonsSincePity;

  DateTime lastSavedAt;
  GameStats stats;

  SaveData({
    this.version = currentVersion,
    this.coin = 0,
    this.totalCoinEarned = 0,
    this.purchasedCoinUnconverted = 0,
    Map<String, int>? tapUpgradeLevels,
    Map<String, int>? autoProducerLevels,
    Map<String, int>? prestigeUpgradeLevels,
    this.parkEssence = 50,
    this.prestigePoints = 0,
    this.prestigeCount = 0,
    Map<String, int>? ownedParts,
    Set<String>? unlockedAchievements,
    Set<String>? unlockedFeatures,
    StockMarketState? market,
    this.totalTaps = 0,
    this.tapsSinceGoldenGuest = 0,
    this.currentCombo = 0,
    this.lastTapAt,
    List<ActiveBooster>? activeBoosters,
    Map<String, DateTime>? skillReadyAt,
    this.dailyMissionDayKey = 0,
    this.weeklyMissionWeekKey = 0,
    Map<String, int>? dailyMissionProgress,
    Set<String>? dailyMissionClaimed,
    Map<String, int>? weeklyMissionProgress,
    Set<String>? weeklyMissionClaimed,
    this.summonsSincePity = 0,
    DateTime? lastSavedAt,
    GameStats? stats,
  })  : tapUpgradeLevels = tapUpgradeLevels ?? <String, int>{},
        autoProducerLevels = autoProducerLevels ?? <String, int>{},
        prestigeUpgradeLevels = prestigeUpgradeLevels ?? <String, int>{},
        ownedParts = ownedParts ?? <String, int>{},
        unlockedAchievements = unlockedAchievements ?? <String>{},
        unlockedFeatures = unlockedFeatures ?? <String>{},
        market = market ?? StockMarketState(),
        activeBoosters = activeBoosters ?? <ActiveBooster>[],
        skillReadyAt = skillReadyAt ?? <String, DateTime>{},
        dailyMissionProgress = dailyMissionProgress ?? <String, int>{},
        dailyMissionClaimed = dailyMissionClaimed ?? <String>{},
        weeklyMissionProgress = weeklyMissionProgress ?? <String, int>{},
        weeklyMissionClaimed = weeklyMissionClaimed ?? <String>{},
        lastSavedAt = lastSavedAt ?? DateTime.now(),
        stats = stats ?? GameStats();

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': version,
        'coin': coin,
        'totalCoinEarned': totalCoinEarned,
        'purchasedCoinUnconverted': purchasedCoinUnconverted,
        'tapUpgradeLevels': tapUpgradeLevels,
        'autoProducerLevels': autoProducerLevels,
        'prestigeUpgradeLevels': prestigeUpgradeLevels,
        'parkEssence': parkEssence,
        'prestigePoints': prestigePoints,
        'prestigeCount': prestigeCount,
        'ownedParts': ownedParts,
        'unlockedAchievements': unlockedAchievements.toList(),
        'unlockedFeatures': unlockedFeatures.toList(),
        'market': market.toJson(),
        'totalTaps': totalTaps,
        'tapsSinceGoldenGuest': tapsSinceGoldenGuest,
        'currentCombo': currentCombo,
        'lastTapAt': lastTapAt?.toIso8601String(),
        'activeBoosters': activeBoosters.map((b) => b.toJson()).toList(),
        'skillReadyAt':
            skillReadyAt.map((k, v) => MapEntry(k, v.toIso8601String())),
        'dailyMissionDayKey': dailyMissionDayKey,
        'weeklyMissionWeekKey': weeklyMissionWeekKey,
        'dailyMissionProgress': dailyMissionProgress,
        'dailyMissionClaimed': dailyMissionClaimed.toList(),
        'weeklyMissionProgress': weeklyMissionProgress,
        'weeklyMissionClaimed': weeklyMissionClaimed.toList(),
        'summonsSincePity': summonsSincePity,
        'lastSavedAt': lastSavedAt.toIso8601String(),
        'stats': stats.toJson(),
      };

  factory SaveData.fromJson(Map<String, dynamic> json) => SaveData(
        version: json['version'] as int? ?? 0,
        coin: (json['coin'] as num?)?.toDouble() ?? 0,
        totalCoinEarned: (json['totalCoinEarned'] as num?)?.toDouble() ?? 0,
        purchasedCoinUnconverted:
            (json['purchasedCoinUnconverted'] as num?)?.toDouble() ?? 0,
        tapUpgradeLevels:
            Map<String, int>.from(json['tapUpgradeLevels'] as Map? ?? {}),
        autoProducerLevels:
            Map<String, int>.from(json['autoProducerLevels'] as Map? ?? {}),
        prestigeUpgradeLevels:
            Map<String, int>.from(json['prestigeUpgradeLevels'] as Map? ?? {}),
        parkEssence: json['parkEssence'] as int? ?? 50,
        prestigePoints: json['prestigePoints'] as int? ?? 0,
        prestigeCount: json['prestigeCount'] as int? ?? 0,
        ownedParts: Map<String, int>.from(json['ownedParts'] as Map? ?? {}),
        unlockedAchievements: ((json['unlockedAchievements'] as List?) ?? [])
            .map((e) => e as String)
            .toSet(),
        unlockedFeatures: ((json['unlockedFeatures'] as List?) ?? [])
            .map((e) => e as String)
            .toSet(),
        market: json['market'] == null
            ? StockMarketState()
            : StockMarketState.fromJson(
                Map<String, dynamic>.from(json['market'] as Map)),
        totalTaps: json['totalTaps'] as int? ?? 0,
        tapsSinceGoldenGuest: json['tapsSinceGoldenGuest'] as int? ?? 0,
        currentCombo: json['currentCombo'] as int? ?? 0,
        lastTapAt: DateTime.tryParse(json['lastTapAt'] as String? ?? ''),
        activeBoosters: ((json['activeBoosters'] as List?) ?? [])
            .map((e) =>
                ActiveBooster.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        skillReadyAt: ((json['skillReadyAt'] as Map?) ?? {}).map(
          (k, v) => MapEntry(
            k as String,
            DateTime.tryParse(v as String? ?? '') ?? DateTime.now(),
          ),
        ),
        dailyMissionDayKey: json['dailyMissionDayKey'] as int? ?? 0,
        weeklyMissionWeekKey: json['weeklyMissionWeekKey'] as int? ?? 0,
        dailyMissionProgress:
            Map<String, int>.from(json['dailyMissionProgress'] as Map? ?? {}),
        dailyMissionClaimed: ((json['dailyMissionClaimed'] as List?) ?? [])
            .map((e) => e as String)
            .toSet(),
        weeklyMissionProgress:
            Map<String, int>.from(json['weeklyMissionProgress'] as Map? ?? {}),
        weeklyMissionClaimed: ((json['weeklyMissionClaimed'] as List?) ?? [])
            .map((e) => e as String)
            .toSet(),
        summonsSincePity: json['summonsSincePity'] as int? ?? 0,
        lastSavedAt: DateTime.tryParse(json['lastSavedAt'] as String? ?? '') ??
            DateTime.now(),
        stats:
            GameStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      );
}
