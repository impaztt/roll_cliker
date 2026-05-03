import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/achievement_catalog.dart';
import '../data/booster_catalog.dart';
import '../data/coaster_part_catalog.dart';
import '../data/exchange_catalog.dart';
import '../data/feature_unlocks.dart';
import '../data/mission_catalog.dart';
import '../data/park_stock_catalog.dart';
import '../data/prestige_upgrade_catalog.dart';
import '../data/producer_catalog.dart';
import '../data/skill_catalog.dart';
import '../data/tap_upgrade_catalog.dart';
import '../models/achievement.dart';
import '../models/booster.dart';
import '../models/coaster_part.dart';
import '../models/mission.dart';
import '../models/prestige_upgrade.dart';
import '../models/save_data.dart';
import '../models/skill.dart';
import '../models/stock_market.dart';
import '../services/save_service.dart';

const Duration tickInterval = Duration(milliseconds: 50);
const Duration comboWindow = Duration(milliseconds: 1500);
const int comboMax = 50;
const double comboPerStack = 0.01;
const double critChance = 0.05;
const double critMultiplier = 10;
const int goldenGuestEveryTaps = 250;
const Duration goldenGuestLifetime = Duration(seconds: 7);
const int goldenGuestHp = 10;
const double goldenGuestRewardMultiplier = 5000;
const Duration offlineCap = Duration(hours: 12);
const double offlineEfficiency = 1.0;

// Stage thresholds (lifetime coin earned).
const List<double> coasterStageThresholdsDouble = [
  0,
  1000,
  100000,
  10000000,
  1e9,
  1e11,
  1e13,
  1e16,
  1e19,
  1e22,
];

enum RidePhase {
  waitingForGuests,
  boarding,
  seating,
  safetyBar,
  ready,
  riding,
  arriving,
  unboarding,
}

class RideState {
  RidePhase phase;
  Duration phaseElapsed;
  Duration phaseDuration;
  int seatedCount;
  int queueCount;
  int rideCount;

  RideState({
    this.phase = RidePhase.waitingForGuests,
    this.phaseElapsed = Duration.zero,
    this.phaseDuration = const Duration(milliseconds: 1500),
    this.seatedCount = 0,
    this.queueCount = 0,
    this.rideCount = 0,
  });
}

class GoldenGuest {
  int hp;
  DateTime spawnedAt;
  GoldenGuest({this.hp = goldenGuestHp, required this.spawnedAt});
  bool get isExpired =>
      DateTime.now().difference(spawnedAt) > goldenGuestLifetime;
}

class FloatingText {
  final String id;
  final String text;
  final Offset origin;
  final Color color;
  final DateTime createdAt;
  final bool critical;

  FloatingText({
    required this.id,
    required this.text,
    required this.origin,
    required this.color,
    required this.createdAt,
    this.critical = false,
  });

  bool get isExpired =>
      DateTime.now().difference(createdAt).inMilliseconds > 1100;
}

class Toast {
  final String id;
  final String text;
  final IconData icon;
  final Color color;
  final DateTime createdAt;
  Toast({
    required this.id,
    required this.text,
    required this.icon,
    required this.color,
    required this.createdAt,
  });
  bool get isExpired =>
      DateTime.now().difference(createdAt).inMilliseconds > 2400;
}

class GameState {
  final SaveData data;
  final RideState ride;
  final GoldenGuest? golden;
  final List<FloatingText> floats;
  final List<Toast> toasts;
  final double cps;
  final double tapPower;
  final int coasterStage;
  final bool offlineRewardPending;
  final double offlineRewardAmount;
  final Duration offlineRewardDuration;
  final bool ready;

  const GameState({
    required this.data,
    required this.ride,
    required this.golden,
    required this.floats,
    required this.toasts,
    required this.cps,
    required this.tapPower,
    required this.coasterStage,
    required this.offlineRewardPending,
    required this.offlineRewardAmount,
    required this.offlineRewardDuration,
    required this.ready,
  });

  GameState copyWith({
    SaveData? data,
    RideState? ride,
    GoldenGuest? golden,
    bool clearGolden = false,
    List<FloatingText>? floats,
    List<Toast>? toasts,
    double? cps,
    double? tapPower,
    int? coasterStage,
    bool? offlineRewardPending,
    double? offlineRewardAmount,
    Duration? offlineRewardDuration,
    bool? ready,
  }) =>
      GameState(
        data: data ?? this.data,
        ride: ride ?? this.ride,
        golden: clearGolden ? null : (golden ?? this.golden),
        floats: floats ?? this.floats,
        toasts: toasts ?? this.toasts,
        cps: cps ?? this.cps,
        tapPower: tapPower ?? this.tapPower,
        coasterStage: coasterStage ?? this.coasterStage,
        offlineRewardPending: offlineRewardPending ?? this.offlineRewardPending,
        offlineRewardAmount: offlineRewardAmount ?? this.offlineRewardAmount,
        offlineRewardDuration:
            offlineRewardDuration ?? this.offlineRewardDuration,
        ready: ready ?? this.ready,
      );
}

class GameNotifier extends Notifier<GameState> {
  late final SaveService _save;
  Timer? _tick;
  Timer? _autoSave;
  Timer? _autoTap;
  final math.Random _rng = math.Random();
  DateTime _lastTickAt = DateTime.now();
  DateTime _lastPriceTickAt = DateTime.now();
  DateTime _lastDividendCheckAt = DateTime.now();
  DateTime? _comboSurgeUntil;
  DateTime? _autoTapUntil;
  int _idSeq = 0;

  @override
  GameState build() {
    _save = SaveService();
    final initial = SaveData();
    final state0 = GameState(
      data: initial,
      ride: RideState(),
      golden: null,
      floats: const <FloatingText>[],
      toasts: const <Toast>[],
      cps: 0,
      tapPower: 1,
      coasterStage: 0,
      offlineRewardPending: false,
      offlineRewardAmount: 0,
      offlineRewardDuration: Duration.zero,
      ready: false,
    );
    Future<void>.microtask(_init);
    ref.onDispose(() {
      _tick?.cancel();
      _autoSave?.cancel();
      _autoTap?.cancel();
    });
    return state0;
  }

  Future<void> _init() async {
    final loaded = await _save.load();
    _seedStockMarket(loaded);
    _refreshMissionPeriods(loaded);
    _refreshUnlocks(loaded);
    final cps = _computeCps(loaded);
    final tap = _computeTapPower(loaded);
    final stage = _computeStage(loaded);

    // Offline reward
    final now = DateTime.now();
    final elapsed = now.difference(loaded.lastSavedAt);
    final clamped = elapsed > offlineCap ? offlineCap : elapsed;
    final eff = offlineEfficiency *
        (1 +
            (loaded.prestigeUpgradeLevels['legacy_offline'] ?? 0) *
                _bonusPerLevelFor('legacy_offline'));
    final offlineCoin =
        cps * clamped.inMilliseconds / 1000.0 * eff;
    final showReward = clamped.inSeconds >= 30 && offlineCoin > 0;

    if (offlineCoin > 0) {
      loaded.coin += offlineCoin;
      loaded.totalCoinEarned += offlineCoin;
    }
    loaded.lastSavedAt = now;

    state = GameState(
      data: loaded,
      ride: RideState(),
      golden: null,
      floats: const <FloatingText>[],
      toasts: const <Toast>[],
      cps: cps,
      tapPower: tap,
      coasterStage: stage,
      offlineRewardPending: showReward,
      offlineRewardAmount: showReward ? offlineCoin : 0,
      offlineRewardDuration: showReward ? clamped : Duration.zero,
      ready: true,
    );

    _lastTickAt = now;
    _lastPriceTickAt = now;
    _lastDividendCheckAt = now;
    _tick = Timer.periodic(tickInterval, (_) => _onTick());
    _autoSave =
        Timer.periodic(const Duration(seconds: 10), (_) => _save.save(state.data));
  }

  void _seedStockMarket(SaveData d) {
    for (final s in parkStockCatalog) {
      final existing = d.market.stocks[s.id];
      if (existing == null) {
        final intrinsic = intrinsicPriceFor(s);
        d.market.stocks[s.id] = StockState(
          id: s.id,
          unlocked: s.order == 1,
          currentPrice: intrinsic,
          intrinsicPrice: intrinsic,
        );
      } else {
        // ensure intrinsic up-to-date in case catalog rebalanced
        existing.intrinsicPrice = intrinsicPriceFor(s);
      }
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // Tick
  // ────────────────────────────────────────────────────────────────────

  void _onTick() {
    final now = DateTime.now();
    final dtMs = now.difference(_lastTickAt).inMilliseconds;
    _lastTickAt = now;
    final dt = dtMs / 1000.0;

    final d = state.data;
    var floats = state.floats.where((f) => !f.isExpired).toList();
    var toasts = state.toasts.where((t) => !t.isExpired).toList();

    // Boosters expire
    final beforeBoosters = d.activeBoosters.length;
    d.activeBoosters.removeWhere((b) => b.isExpired);
    final boostersChanged = beforeBoosters != d.activeBoosters.length;

    // Combo decay
    if (d.lastTapAt != null &&
        now.difference(d.lastTapAt!) > comboWindow &&
        d.currentCombo != 0) {
      d.currentCombo = 0;
    }
    if (_comboSurgeUntil != null && now.isAfter(_comboSurgeUntil!)) {
      _comboSurgeUntil = null;
    }
    if (_autoTapUntil != null && now.isAfter(_autoTapUntil!)) {
      _autoTapUntil = null;
      _autoTap?.cancel();
      _autoTap = null;
    }

    // CPS gain
    final cps = _computeCps(d);
    if (cps > 0 && dt > 0) {
      final gain = cps * dt;
      d.coin += gain;
      d.totalCoinEarned += gain;
    }

    // Ride cycle progression
    final ride = state.ride;
    ride.phaseElapsed += Duration(milliseconds: dtMs);
    final speedScale = _rideSpeedScale(d);
    final scaled = Duration(
      milliseconds: (ride.phaseDuration.inMilliseconds / speedScale).ceil(),
    );
    if (ride.phaseElapsed >= scaled) {
      _advanceRide(ride, d, floats);
    }

    // Golden guest expiry
    GoldenGuest? golden = state.golden;
    bool clearGolden = false;
    if (golden != null && golden.isExpired) {
      clearGolden = true;
      golden = null;
    }

    // Stock market 1s tick
    if (now.difference(_lastPriceTickAt) >= priceTickInterval) {
      final ticks = now.difference(_lastPriceTickAt).inSeconds;
      _lastPriceTickAt = now;
      for (var i = 0; i < ticks && i < 60; i++) {
        _stockMarketStep(d, now);
      }
    }
    if (now.difference(_lastDividendCheckAt).inSeconds >= 60) {
      _lastDividendCheckAt = now;
      _accrueDividends(d, now);
    }

    // Unlocks check
    _refreshUnlocks(d);
    _checkAchievements(d);

    final tap = _computeTapPower(d);
    final stage = _computeStage(d);
    state = state.copyWith(
      data: d,
      ride: ride,
      golden: golden,
      clearGolden: clearGolden,
      floats: floats,
      toasts: toasts,
      cps: cps,
      tapPower: tap,
      coasterStage: stage,
    );

    if (boostersChanged) {
      // ensure UI updates
    }
  }

  void _advanceRide(RideState ride, SaveData d, List<FloatingText> floats) {
    final next = _nextPhase(ride.phase);
    ride.phase = next;
    ride.phaseElapsed = Duration.zero;
    switch (next) {
      case RidePhase.waitingForGuests:
        ride.phaseDuration = const Duration(milliseconds: 1500);
        ride.queueCount = 0;
        ride.seatedCount = 0;
        break;
      case RidePhase.boarding:
        ride.phaseDuration = const Duration(milliseconds: 1500);
        ride.queueCount = 4 + _rng.nextInt(5);
        break;
      case RidePhase.seating:
        ride.phaseDuration = const Duration(milliseconds: 1000);
        ride.seatedCount = ride.queueCount;
        break;
      case RidePhase.safetyBar:
        ride.phaseDuration = const Duration(milliseconds: 1000);
        break;
      case RidePhase.ready:
        ride.phaseDuration = const Duration(milliseconds: 500);
        break;
      case RidePhase.riding:
        ride.phaseDuration = const Duration(seconds: 10);
        break;
      case RidePhase.arriving:
        ride.phaseDuration = const Duration(milliseconds: 800);
        break;
      case RidePhase.unboarding:
        ride.phaseDuration = const Duration(milliseconds: 1500);
        // Settle ride bonus: small flat tip on top of CPS to give visible coin pop
        final tip = state.cps * 4 + 10;
        d.coin += tip;
        d.totalCoinEarned += tip;
        ride.rideCount += 1;
        d.stats.totalRides += 1;
        _bumpMission(d, MissionMetric.ride, 1);
        break;
    }
  }

  RidePhase _nextPhase(RidePhase p) {
    switch (p) {
      case RidePhase.waitingForGuests:
        return RidePhase.boarding;
      case RidePhase.boarding:
        return RidePhase.seating;
      case RidePhase.seating:
        return RidePhase.safetyBar;
      case RidePhase.safetyBar:
        return RidePhase.ready;
      case RidePhase.ready:
        return RidePhase.riding;
      case RidePhase.riding:
        return RidePhase.arriving;
      case RidePhase.arriving:
        return RidePhase.unboarding;
      case RidePhase.unboarding:
        return RidePhase.waitingForGuests;
    }
  }

  // The ride speeds up with progression.
  double _rideSpeedScale(SaveData d) {
    final lifetime = d.totalCoinEarned;
    if (lifetime < 1e3) return 1.0;
    if (lifetime < 1e6) return 1.3;
    if (lifetime < 1e9) return 1.9;
    if (lifetime < 1e12) return 3.1;
    return 5.0;
  }

  // ────────────────────────────────────────────────────────────────────
  // Math
  // ────────────────────────────────────────────────────────────────────

  double _bonusPerLevelFor(String upgradeId) {
    for (final u in prestigeUpgradeCatalog) {
      if (u.id == upgradeId) return u.bonusPerLevel;
    }
    return 0;
  }

  double _multiplierForEffect(SaveData d, PrestigeEffectKind kind) {
    var bonus = 0.0;
    for (final u in prestigeUpgradeCatalog) {
      if (u.effect != kind) continue;
      final lv = d.prestigeUpgradeLevels[u.id] ?? 0;
      bonus += lv * u.bonusPerLevel;
    }
    return 1 + bonus;
  }

  double prestigeOverallMultiplier(SaveData d) {
    final pointBonus = 1 + d.prestigePoints * 0.02;
    final upgradeBonus = _multiplierForEffect(d, PrestigeEffectKind.overall);
    final allBonus = _multiplierForEffect(d, PrestigeEffectKind.tapAndCps);
    return pointBonus * upgradeBonus * allBonus;
  }

  ({double tap, double cps, double goldenChance}) _setBonuses(SaveData d) {
    var tap = 0.0;
    var cps = 0.0;
    var golden = 0.0;
    for (final part in coasterPartCatalog) {
      final owned = (d.ownedParts[part.id] ?? 0).clamp(0, 9999);
      if (owned > 0) {
        tap += part.tapBonus * owned;
        cps += part.cpsBonus * owned;
        golden += part.goldenChanceBonus * owned;
      }
    }
    for (final set in coasterSetCatalog) {
      final pieces = set.partIds
          .where((id) => (d.ownedParts[id] ?? 0) > 0)
          .length;
      var bestTap = 0.0, bestCps = 0.0, bestAll = 0.0;
      for (final entry in set.tapBonus.entries) {
        if (pieces >= entry.key) bestTap += entry.value;
      }
      for (final entry in set.cpsBonus.entries) {
        if (pieces >= entry.key) bestCps += entry.value;
      }
      for (final entry in set.overallBonus.entries) {
        if (pieces >= entry.key) bestAll += entry.value;
      }
      tap += bestTap + bestAll;
      cps += bestCps + bestAll;
    }
    return (tap: 1 + tap, cps: 1 + cps, goldenChance: golden);
  }

  double _boosterMultFor(SaveData d, BoosterKind kind) {
    var m = 1.0;
    for (final b in d.activeBoosters) {
      if (b.kind == kind || b.kind == BoosterKind.rush) {
        m *= b.multiplier;
      }
    }
    return m;
  }

  double _computeTapPower(SaveData d) {
    var base = 1.0;
    for (final t in tapUpgradeCatalog) {
      final lv = d.tapUpgradeLevels[t.id] ?? 0;
      base += t.tapPowerPerLevel * lv;
    }
    final overall = prestigeOverallMultiplier(d);
    final tapMult = _multiplierForEffect(d, PrestigeEffectKind.tap);
    final boosters = _boosterMultFor(d, BoosterKind.tap);
    final sets = _setBonuses(d);
    return base * overall * tapMult * boosters * sets.tap;
  }

  double _computeCps(SaveData d) {
    var sum = 0.0;
    for (final p in producerCatalog) {
      final lv = d.autoProducerLevels[p.id] ?? 0;
      if (lv > 0) sum += p.cpsAtLevel(lv);
    }
    final overall = prestigeOverallMultiplier(d);
    final cpsMult = _multiplierForEffect(d, PrestigeEffectKind.cps);
    final boosters = _boosterMultFor(d, BoosterKind.cps);
    final sets = _setBonuses(d);
    return sum * overall * cpsMult * boosters * sets.cps;
  }

  int _computeStage(SaveData d) {
    var stage = 0;
    for (var i = 0; i < coasterStageThresholdsDouble.length; i++) {
      if (d.totalCoinEarned >= coasterStageThresholdsDouble[i]) {
        stage = i;
      }
    }
    return stage;
  }

  // ────────────────────────────────────────────────────────────────────
  // Tap
  // ────────────────────────────────────────────────────────────────────

  void onTap(Offset origin) {
    final d = state.data;
    final now = DateTime.now();
    final inCombo = d.lastTapAt != null && now.difference(d.lastTapAt!) <= comboWindow;
    final surge = _comboSurgeUntil != null && now.isBefore(_comboSurgeUntil!);
    final stackInc = surge ? 2 : 1;
    if (inCombo) {
      d.currentCombo = (d.currentCombo + stackInc).clamp(0, comboMax);
    } else {
      d.currentCombo = stackInc.clamp(0, comboMax);
    }
    d.lastTapAt = now;
    d.totalTaps += 1;
    d.tapsSinceGoldenGuest += 1;
    d.stats.totalTaps += 1;
    _bumpMission(d, MissionMetric.tap, 1);

    // Compute reward
    final tapBase = _computeTapPower(d);
    final comboBonus = 1 + d.currentCombo * comboPerStack;
    var reward = tapBase * comboBonus;
    final crit = _rng.nextDouble() < critChance;
    if (crit) {
      reward *= critMultiplier;
      d.stats.totalCriticals += 1;
      _bumpMission(d, MissionMetric.critical, 1);
    }
    final surgeMult = surge ? 2.0 : 1.0;
    reward *= surgeMult;

    d.coin += reward;
    d.totalCoinEarned += reward;

    // Combo burst at 50
    final newFloats = List<FloatingText>.from(state.floats);
    final newToasts = List<Toast>.from(state.toasts);
    if (d.currentCombo >= comboMax) {
      // grant 60 seconds of CPS
      final burst = state.cps * 60;
      if (burst > 0) {
        d.coin += burst;
        d.totalCoinEarned += burst;
      }
      d.stats.totalComboBursts += 1;
      _bumpMission(d, MissionMetric.comboBurst, 1);
      d.currentCombo = 0;
      newToasts.add(Toast(
        id: _newId(),
        text: '만석 대박 운행! +${_short(burst)}',
        icon: Icons.celebration,
        color: const Color(0xFFFFCA28),
        createdAt: DateTime.now(),
      ));
    }

    newFloats.add(FloatingText(
      id: _newId(),
      text: '+${_short(reward)}',
      origin: origin,
      color: crit ? const Color(0xFFEF5350) : const Color(0xFFFFA726),
      createdAt: DateTime.now(),
      critical: crit,
    ));

    // Golden guest spawn
    GoldenGuest? golden = state.golden;
    if (golden == null && d.tapsSinceGoldenGuest >= goldenGuestEveryTaps) {
      d.tapsSinceGoldenGuest = 0;
      golden = GoldenGuest(spawnedAt: DateTime.now());
    }

    state = state.copyWith(
      data: d,
      golden: golden,
      floats: newFloats,
      toasts: newToasts,
    );
  }

  void onTapGolden(Offset origin) {
    final d = state.data;
    var golden = state.golden;
    if (golden == null) return;
    golden.hp -= 1;
    final newFloats = List<FloatingText>.from(state.floats);
    final newToasts = List<Toast>.from(state.toasts);
    if (golden.hp <= 0) {
      final reward = _computeTapPower(d) * goldenGuestRewardMultiplier;
      d.coin += reward;
      d.totalCoinEarned += reward;
      d.stats.totalGoldenGuests += 1;
      _bumpMission(d, MissionMetric.goldenGuest, 1);
      golden = null;
      newToasts.add(Toast(
        id: _newId(),
        text: '황금 손님 탑승! +${_short(reward)}',
        icon: Icons.emoji_emotions,
        color: const Color(0xFFFFCA28),
        createdAt: DateTime.now(),
      ));
      newFloats.add(FloatingText(
        id: _newId(),
        text: '+${_short(reward)}',
        origin: origin,
        color: const Color(0xFFFFCA28),
        createdAt: DateTime.now(),
        critical: true,
      ));
    } else {
      newFloats.add(FloatingText(
        id: _newId(),
        text: '★',
        origin: origin,
        color: const Color(0xFFFFD54F),
        createdAt: DateTime.now(),
      ));
    }
    state = state.copyWith(
      data: d,
      golden: golden,
      clearGolden: golden == null,
      floats: newFloats,
      toasts: newToasts,
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Upgrades
  // ────────────────────────────────────────────────────────────────────

  bool buyTapUpgrade(String id) {
    final def = tapUpgradeCatalog.firstWhere((t) => t.id == id);
    final d = state.data;
    final lv = d.tapUpgradeLevels[id] ?? 0;
    final cost = def.costForLevel(lv);
    if (d.coin < cost) return false;
    d.coin -= cost;
    _consumeUnconverted(d, cost);
    d.tapUpgradeLevels[id] = lv + 1;
    d.stats.totalUpgradesPurchased += 1;
    _bumpMission(d, MissionMetric.upgradePurchase, 1);
    state = state.copyWith(data: d);
    return true;
  }

  bool buyAutoProducer(String id) {
    final def = producerCatalog.firstWhere((p) => p.id == id);
    final d = state.data;
    final lv = d.autoProducerLevels[id] ?? 0;
    final cost = def.costForLevel(lv);
    if (d.coin < cost) return false;
    d.coin -= cost;
    _consumeUnconverted(d, cost);
    d.autoProducerLevels[id] = lv + 1;
    d.stats.totalUpgradesPurchased += 1;
    _bumpMission(d, MissionMetric.upgradePurchase, 1);
    state = state.copyWith(data: d, cps: _computeCps(d));
    return true;
  }

  bool buyPrestigeUpgrade(String id) {
    final def = prestigeUpgradeCatalog.firstWhere((u) => u.id == id);
    final d = state.data;
    final lv = d.prestigeUpgradeLevels[id] ?? 0;
    final cost = def.costForLevel(lv);
    if (d.prestigePoints < cost) return false;
    d.prestigePoints -= cost;
    d.prestigeUpgradeLevels[id] = lv + 1;
    state = state.copyWith(data: d);
    return true;
  }

  void _consumeUnconverted(SaveData d, double amount) {
    if (d.purchasedCoinUnconverted <= 0) return;
    d.purchasedCoinUnconverted =
        (d.purchasedCoinUnconverted - amount).clamp(0.0, double.infinity);
  }

  // ────────────────────────────────────────────────────────────────────
  // Boosters & skills
  // ────────────────────────────────────────────────────────────────────

  bool useBooster(String id) {
    final def = boosterCatalog.firstWhere((b) => b.id == id);
    final d = state.data;
    if (d.parkEssence < def.essenceCost) return false;
    d.parkEssence -= def.essenceCost;
    d.activeBoosters.add(ActiveBooster(
      id: def.id,
      kind: def.kind,
      multiplier: def.multiplier,
      expiresAt: DateTime.now().add(def.duration),
    ));
    d.stats.totalBoosterUses += 1;
    _bumpMission(d, MissionMetric.boosterUse, 1);
    state = state.copyWith(data: d);
    return true;
  }

  bool useSkill(String id) {
    final def = skillCatalog.firstWhere((s) => s.id == id);
    final now = DateTime.now();
    final ready = state.data.skillReadyAt[id];
    if (ready != null && now.isBefore(ready)) return false;
    final d = state.data;
    final newToasts = List<Toast>.from(state.toasts);
    switch (def.kind) {
      case SkillKind.turboBurst:
        final amt = state.cps * def.amount;
        d.coin += amt;
        d.totalCoinEarned += amt;
        newToasts.add(Toast(
          id: _newId(),
          text: '터보 출발! +${_short(amt)}',
          icon: def.icon,
          color: def.accent,
          createdAt: now,
        ));
        break;
      case SkillKind.comboSurge:
        _comboSurgeUntil = now.add(def.duration);
        newToasts.add(_skillToast(def, '콤보 서지 발동!'));
        break;
      case SkillKind.essenceGather:
        d.parkEssence += def.amount.toInt();
        newToasts.add(Toast(
          id: _newId(),
          text: '정수 +${def.amount.toInt()}',
          icon: def.icon,
          color: def.accent,
          createdAt: now,
        ));
        break;
      case SkillKind.autoTap:
        _autoTapUntil = now.add(def.duration);
        _autoTap?.cancel();
        _autoTap = Timer.periodic(const Duration(milliseconds: 250), (_) {
          if (_autoTapUntil == null || DateTime.now().isAfter(_autoTapUntil!)) {
            _autoTap?.cancel();
            _autoTap = null;
            return;
          }
          onTap(const Offset(0.5, 0.5));
        });
        newToasts.add(_skillToast(def, '자동 출발 발동!'));
        break;
      case SkillKind.rushBooster:
        d.activeBoosters.add(ActiveBooster(
          id: 'skill_rush',
          kind: BoosterKind.rush,
          multiplier: 3,
          expiresAt: now.add(def.duration),
        ));
        newToasts.add(_skillToast(def, '골드러시 운행 발동!'));
        break;
      case SkillKind.callQueue:
        // Skip the wait — push ride into seating with a full queue
        final r = state.ride;
        r.phase = RidePhase.seating;
        r.phaseElapsed = Duration.zero;
        r.phaseDuration = const Duration(milliseconds: 500);
        r.queueCount = 8;
        r.seatedCount = 8;
        newToasts.add(_skillToast(def, '대기열 만석!'));
        break;
      case SkillKind.goldenSummon:
        if (state.golden == null) {
          state =
              state.copyWith(golden: GoldenGuest(spawnedAt: DateTime.now()));
        }
        newToasts.add(_skillToast(def, '황금 손님 등장!'));
        break;
    }
    d.skillReadyAt[id] = now.add(def.cooldown);
    d.stats.totalSkillUses += 1;
    _bumpMission(d, MissionMetric.skillUse, 1);
    state = state.copyWith(data: d, toasts: newToasts);
    return true;
  }

  Toast _skillToast(SkillDef def, String text) => Toast(
        id: _newId(),
        text: text,
        icon: def.icon,
        color: def.accent,
        createdAt: DateTime.now(),
      );

  Duration? skillCooldownLeft(String id) {
    final ready = state.data.skillReadyAt[id];
    if (ready == null) return null;
    final delta = ready.difference(DateTime.now());
    return delta.isNegative ? null : delta;
  }

  // ────────────────────────────────────────────────────────────────────
  // Prestige (Renewal)
  // ────────────────────────────────────────────────────────────────────

  int prestigePotential() {
    final d = state.data;
    final autoSum = d.autoProducerLevels.values.fold<int>(0, (a, b) => a + b);
    final tapSum = d.tapUpgradeLevels.values.fold<int>(0, (a, b) => a + b);
    final base = math.sqrt(d.totalCoinEarned / 1e7) +
        autoSum / 30.0 +
        tapSum / 20.0 +
        d.prestigeCount * 0.2;
    final mult = _multiplierForEffect(d, PrestigeEffectKind.prestigeGain);
    final result = (base * mult).floor();
    return result < 0 ? 0 : result;
  }

  bool canPrestige() => prestigePotential() >= 1;

  void prestige() {
    if (!canPrestige()) return;
    final d = state.data;
    final gained = prestigePotential();
    d.prestigePoints += gained;
    d.prestigeCount += 1;
    _bumpMission(d, MissionMetric.prestige, 1);
    // Reset per-run progress
    d.coin = 0;
    d.totalCoinEarned = 0;
    d.purchasedCoinUnconverted = 0;
    d.tapUpgradeLevels.clear();
    d.autoProducerLevels.clear();
    d.currentCombo = 0;
    d.tapsSinceGoldenGuest = 0;
    state = state.copyWith(
      data: d,
      ride: RideState(),
      golden: null,
      clearGolden: true,
      cps: _computeCps(d),
      tapPower: _computeTapPower(d),
      coasterStage: _computeStage(d),
      toasts: [
        ...state.toasts,
        Toast(
          id: _newId(),
          text: '리뉴얼 오픈! +$gained 명성',
          icon: Icons.refresh,
          color: const Color(0xFFFFA726),
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Stock Market
  // ────────────────────────────────────────────────────────────────────

  void _stockMarketStep(SaveData d, DateTime now) {
    for (final def in parkStockCatalog) {
      final s = d.market.stocks[def.id];
      if (s == null || !s.unlocked) continue;
      // Random walk with mean reversion to intrinsic.
      final shock = (_rng.nextDouble() * 2 - 1) * def.volatility;
      final reversion = (s.intrinsicPrice - s.currentPrice) /
          s.intrinsicPrice *
          0.0008;
      final change = shock + reversion;
      var next = s.currentPrice * (1 + change);
      final floor = s.intrinsicPrice * priceFloorMultiple;
      final ceil = s.intrinsicPrice * priceCeilingMultiple;
      next = next.clamp(floor, ceil);
      s.currentPrice = next;

      // Candle aggregation
      final forming = s.formingCandle;
      if (forming == null ||
          now.difference(forming.startedAt) >= candleSpan) {
        if (forming != null) {
          s.recentCandles.add(forming);
          while (s.recentCandles.length > maxCandlesPerStock) {
            s.recentCandles.removeAt(0);
          }
        }
        s.formingCandle = Candle(
          open: next,
          high: next,
          low: next,
          close: next,
          startedAt: now,
        );
      } else {
        forming.close = next;
        if (next > forming.high) forming.high = next;
        if (next < forming.low) forming.low = next;
      }
    }
  }

  void _accrueDividends(SaveData d, DateTime now) {
    final mult = _multiplierForEffect(d, PrestigeEffectKind.market);
    for (final def in parkStockCatalog) {
      final s = d.market.stocks[def.id];
      if (s == null || !s.unlocked || s.shares == 0) continue;
      final last = s.lastAccrualAt ?? now;
      final hours = now.difference(last).inMinutes / 60.0;
      if (hours <= 0) continue;
      final value = s.currentPrice * s.shares;
      final divPerHour = value * def.dividendRate * mult;
      s.pendingDividend += divPerHour * hours;
      s.lastAccrualAt = now;
    }
  }

  bool buyShares(String stockId, int count) {
    final def = stockById(stockId);
    final d = state.data;
    final s = d.market.stocks[stockId];
    if (def == null || s == null || !s.unlocked || count <= 0) return false;
    final price = s.currentPrice;
    final gross = price * count;
    final fee = gross * tradeFeeRate;
    final total = gross + fee;
    if (d.coin < total) return false;
    final ratio = (s.shares + count) / totalSharesPerStock;
    if (ratio > maxOwnershipRatio) return false;
    d.coin -= total;
    _consumeUnconverted(d, total);
    final prevValue = s.avgCost * s.shares;
    final newShares = s.shares + count;
    s.avgCost = (prevValue + gross) / newShares;
    s.shares = newShares;
    s.lastAccrualAt = DateTime.now();
    d.market.totalTrades += 1;
    d.market.totalFeesPaid += fee;
    _checkUnlockNextStock(d, def);
    state = state.copyWith(data: d);
    return true;
  }

  bool sellShares(String stockId, int count) {
    final d = state.data;
    final s = d.market.stocks[stockId];
    if (s == null || count <= 0 || count > s.shares) return false;
    final gross = s.currentPrice * count;
    final fee = gross * tradeFeeRate;
    final net = gross - fee;
    final cost = s.avgCost * count;
    final realized = net - cost;
    d.coin += net;
    d.totalCoinEarned += net > 0 ? net - cost : 0;
    s.shares -= count;
    if (s.shares == 0) {
      s.avgCost = 0;
    }
    d.market.totalTrades += 1;
    d.market.totalFeesPaid += fee;
    d.market.totalRealizedProfit += realized;
    state = state.copyWith(data: d);
    return true;
  }

  void claimDividend(String stockId) {
    final d = state.data;
    final s = d.market.stocks[stockId];
    if (s == null || s.pendingDividend <= 0) return;
    final amt = s.pendingDividend;
    d.coin += amt;
    d.totalCoinEarned += amt;
    d.market.totalDividendsClaimed += amt;
    s.pendingDividend = 0;
    _bumpAchievement(d, AchievementMetric.marketDividend, 1);
    state = state.copyWith(data: d);
  }

  void _checkUnlockNextStock(SaveData d, StockDef def) {
    final s = d.market.stocks[def.id];
    if (s == null) return;
    final ratio = s.shares / totalSharesPerStock;
    if (ratio < unlockOwnershipRatio) return;
    final next = parkStockCatalog
        .where((x) => x.order == def.order + 1)
        .cast<StockDef?>()
        .firstWhere((x) => x != null, orElse: () => null);
    if (next == null) return;
    final ns = d.market.stocks[next.id];
    if (ns != null && !ns.unlocked) {
      ns.unlocked = true;
      state = state.copyWith(toasts: [
        ...state.toasts,
        Toast(
          id: _newId(),
          text: '신규 종목 해금: ${next.name}',
          icon: Icons.show_chart,
          color: const Color(0xFF80CBC4),
          createdAt: DateTime.now(),
        ),
      ]);
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // Exchange
  // ────────────────────────────────────────────────────────────────────

  bool buyExchange(String offerId) {
    final offer = exchangeOffers.firstWhere((o) => o.id == offerId);
    final d = state.data;
    if (d.parkEssence < offer.essenceCost) return false;
    final payout = offer.flatCoin > 0
        ? offer.flatCoin * offer.payoutRatio
        : state.cps * offer.cpsMinutes * 60 * offer.payoutRatio;
    if (payout <= 0) return false;
    d.parkEssence -= offer.essenceCost;
    d.coin += payout;
    d.purchasedCoinUnconverted += payout;
    state = state.copyWith(data: d, toasts: [
      ...state.toasts,
      Toast(
        id: _newId(),
        text: '${offer.name} → +${_short(payout)} 코인',
        icon: Icons.swap_horiz,
        color: const Color(0xFFFFAB91),
        createdAt: DateTime.now(),
      ),
    ]);
    return true;
  }

  // ────────────────────────────────────────────────────────────────────
  // Summon (gacha)
  // ────────────────────────────────────────────────────────────────────

  static const int summonCost = 50;
  static const int pityThreshold = 80;

  CoasterPartDef? summon() {
    final d = state.data;
    if (d.parkEssence < summonCost) return null;
    d.parkEssence -= summonCost;
    d.summonsSincePity += 1;
    d.stats.totalSummons += 1;
    _bumpMission(d, MissionMetric.summon, 1);

    final guaranteed = d.summonsSincePity >= pityThreshold;
    final part = _rollPart(guaranteed: guaranteed);
    if (part.rarity.isSrPlus) d.summonsSincePity = 0;
    d.ownedParts.update(part.id, (v) => v + 1, ifAbsent: () => 1);

    state = state.copyWith(data: d, toasts: [
      ...state.toasts,
      Toast(
        id: _newId(),
        text: '${part.rarity.label} ${part.name}',
        icon: part.icon,
        color: part.rarity.color,
        createdAt: DateTime.now(),
      ),
    ]);
    return part;
  }

  CoasterPartDef _rollPart({bool guaranteed = false}) {
    if (guaranteed) {
      final pool =
          coasterPartCatalog.where((p) => p.rarity.isSrPlus).toList();
      return pool[_rng.nextInt(pool.length)];
    }
    final r = _rng.nextDouble();
    PartRarity rarity;
    if (r < 0.55) {
      rarity = PartRarity.n;
    } else if (r < 0.85) {
      rarity = PartRarity.r;
    } else if (r < 0.96) {
      rarity = PartRarity.sr;
    } else if (r < 0.995) {
      rarity = PartRarity.ssr;
    } else if (r < 0.999) {
      rarity = PartRarity.lr;
    } else {
      rarity = PartRarity.ur;
    }
    final pool =
        coasterPartCatalog.where((p) => p.rarity == rarity).toList();
    if (pool.isEmpty) {
      // Fallback to any common
      final common =
          coasterPartCatalog.where((p) => p.rarity == PartRarity.n).toList();
      return common[_rng.nextInt(common.length)];
    }
    return pool[_rng.nextInt(pool.length)];
  }

  // ────────────────────────────────────────────────────────────────────
  // Missions
  // ────────────────────────────────────────────────────────────────────

  int _todayKey() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  int _weekKey() {
    final now = DateTime.now();
    final dayOfYear = int.parse(
        '${now.difference(DateTime(now.year, 1, 1)).inDays}');
    return now.year * 100 + (dayOfYear ~/ 7);
  }

  void _refreshMissionPeriods(SaveData d) {
    final tk = _todayKey();
    if (d.dailyMissionDayKey != tk) {
      d.dailyMissionDayKey = tk;
      d.dailyMissionProgress.clear();
      d.dailyMissionClaimed.clear();
    }
    final wk = _weekKey();
    if (d.weeklyMissionWeekKey != wk) {
      d.weeklyMissionWeekKey = wk;
      d.weeklyMissionProgress.clear();
      d.weeklyMissionClaimed.clear();
    }
  }

  void _bumpMission(SaveData d, MissionMetric metric, int by) {
    _refreshMissionPeriods(d);
    for (final m in dailyMissions) {
      if (m.metric == metric) {
        d.dailyMissionProgress.update(m.id, (v) => v + by, ifAbsent: () => by);
      }
    }
    for (final m in weeklyMissions) {
      if (m.metric == metric) {
        d.weeklyMissionProgress.update(m.id, (v) => v + by, ifAbsent: () => by);
      }
    }
    _bumpAchievement(d, _missionToAchievement(metric), by.toDouble());
  }

  AchievementMetric _missionToAchievement(MissionMetric m) {
    switch (m) {
      case MissionMetric.tap:
        return AchievementMetric.tap;
      case MissionMetric.goldenGuest:
        return AchievementMetric.goldenGuest;
      case MissionMetric.summon:
        return AchievementMetric.summon;
      case MissionMetric.prestige:
        return AchievementMetric.prestige;
      case MissionMetric.ride:
        return AchievementMetric.ride;
      default:
        return AchievementMetric.tap; // benign
    }
  }

  bool claimDailyMission(String id) {
    final d = state.data;
    if (d.dailyMissionClaimed.contains(id)) return false;
    final m = dailyMissions.firstWhere((x) => x.id == id);
    final progress = d.dailyMissionProgress[id] ?? 0;
    if (progress < m.target) return false;
    d.dailyMissionClaimed.add(id);
    d.parkEssence += m.essenceReward;
    d.prestigePoints += m.prestigeReward;
    state = state.copyWith(data: d);
    return true;
  }

  bool claimWeeklyMission(String id) {
    final d = state.data;
    if (d.weeklyMissionClaimed.contains(id)) return false;
    final m = weeklyMissions.firstWhere((x) => x.id == id);
    final progress = d.weeklyMissionProgress[id] ?? 0;
    if (progress < m.target) return false;
    d.weeklyMissionClaimed.add(id);
    d.parkEssence += m.essenceReward;
    d.prestigePoints += m.prestigeReward;
    state = state.copyWith(data: d);
    return true;
  }

  // ────────────────────────────────────────────────────────────────────
  // Achievements
  // ────────────────────────────────────────────────────────────────────

  void _bumpAchievement(SaveData d, AchievementMetric metric, double by) {
    // Achievements are checked on tick using current state; no per-event store.
  }

  void _checkAchievements(SaveData d) {
    for (final a in achievementCatalog) {
      if (d.unlockedAchievements.contains(a.id)) continue;
      double current;
      switch (a.metric) {
        case AchievementMetric.tap:
          current = d.totalTaps.toDouble();
          break;
        case AchievementMetric.totalCoin:
          current = d.totalCoinEarned;
          break;
        case AchievementMetric.prestige:
          current = d.prestigeCount.toDouble();
          break;
        case AchievementMetric.goldenGuest:
          current = d.stats.totalGoldenGuests.toDouble();
          break;
        case AchievementMetric.summon:
          current = d.stats.totalSummons.toDouble();
          break;
        case AchievementMetric.partOwned:
          current = d.ownedParts.keys.length.toDouble();
          break;
        case AchievementMetric.ride:
          current = d.stats.totalRides.toDouble();
          break;
        case AchievementMetric.marketTrade:
          current = d.market.totalTrades.toDouble();
          break;
        case AchievementMetric.marketDividend:
          current = d.market.totalDividendsClaimed > 0 ? 1 : 0;
          break;
      }
      if (current >= a.target) {
        d.unlockedAchievements.add(a.id);
        d.parkEssence += a.essenceReward;
        state = state.copyWith(data: d, toasts: [
          ...state.toasts,
          Toast(
            id: _newId(),
            text: '업적 달성: ${a.title}',
            icon: Icons.emoji_events,
            color: const Color(0xFFFFCA28),
            createdAt: DateTime.now(),
          ),
        ]);
      }
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // Feature unlocks
  // ────────────────────────────────────────────────────────────────────

  void _refreshUnlocks(SaveData d) {
    final u = d.unlockedFeatures;
    if (d.totalTaps >= 1) u.add(FeatureGate.missions.name);
    if (d.parkEssence >= 50) u.add(FeatureGate.summon.name);
    if (d.unlockedAchievements.isNotEmpty) u.add(FeatureGate.achievements.name);
    if (canPrestige() || d.prestigeCount > 0) {
      u.add(FeatureGate.prestige.name);
    }
    if (d.prestigeCount >= 1) {
      u.add(FeatureGate.boosterShop.name);
      u.add(FeatureGate.exchange.name);
    } else if (d.totalCoinEarned >= 1e8) {
      u.add(FeatureGate.exchange.name);
    }
    if (d.totalCoinEarned >= stockMarketLifetimeCoinTrigger) {
      u.add(FeatureGate.stockMarket.name);
    }
  }

  bool isFeatureUnlocked(FeatureGate g) =>
      state.data.unlockedFeatures.contains(g.name);

  // ────────────────────────────────────────────────────────────────────
  // Misc
  // ────────────────────────────────────────────────────────────────────

  void clearOfflineReward() {
    state = state.copyWith(
      offlineRewardPending: false,
      offlineRewardAmount: 0,
      offlineRewardDuration: Duration.zero,
    );
  }

  Future<void> forceSave() => _save.save(state.data);

  Future<void> hardReset() async {
    await _save.wipe();
    final fresh = SaveData();
    _seedStockMarket(fresh);
    state = state.copyWith(
      data: fresh,
      ride: RideState(),
      golden: null,
      clearGolden: true,
      cps: 0,
      tapPower: 1,
      coasterStage: 0,
    );
  }

  String _newId() {
    _idSeq++;
    return 'id_$_idSeq';
  }

  String _short(double v) {
    if (v < 1000) return v.floor().toString();
    const suffixes = ['', 'K', 'M', 'B', 'T'];
    var t = 0;
    var x = v;
    while (x >= 1000 && t < suffixes.length - 1) {
      x /= 1000;
      t++;
    }
    if (t == suffixes.length - 1 && x >= 1000) {
      // Fall back to scientific
      return v.toStringAsExponential(2);
    }
    return '${x.toStringAsFixed(2)}${suffixes[t]}';
  }
}

final gameProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
