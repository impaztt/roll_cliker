import 'package:flutter/material.dart';

class AutoProducerDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color accent;
  final double baseCost;
  final double baseCps;

  const AutoProducerDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.accent,
    required this.baseCost,
    required this.baseCps,
  });

  /// price = baseCost × 1.15^level
  double costForLevel(int level) {
    var v = baseCost;
    for (var i = 0; i < level; i++) {
      v *= 1.15;
    }
    return v;
  }

  /// CPS at the given level, including milestone multipliers.
  double cpsAtLevel(int level) {
    if (level <= 0) return 0;
    var mult = 1.0;
    if (level >= 25) mult *= 2;
    if (level >= 50) mult *= 2;
    if (level >= 100) mult *= 2;
    if (level >= 200) mult *= 2;
    if (level >= 500) mult *= 3;
    if (level >= 1000) mult *= 5;
    return baseCps * level * mult;
  }

  /// Next milestone level (or null if none) and the multiplier it grants.
  ({int nextLevel, double mult})? nextMilestone(int level) {
    const milestones = <int, double>{
      25: 2,
      50: 2,
      100: 2,
      200: 2,
      500: 3,
      1000: 5,
    };
    for (final entry in milestones.entries) {
      if (level < entry.key) {
        return (nextLevel: entry.key, mult: entry.value);
      }
    }
    return null;
  }
}
