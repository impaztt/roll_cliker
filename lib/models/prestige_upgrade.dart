import 'package:flutter/material.dart';

enum PrestigeEffectKind {
  overall,
  tap,
  cps,
  tapAndCps,
  prestigeGain,
  offline,
  market,
}

class PrestigeUpgradeDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color accent;
  final int baseCost;
  final double growth;
  final double bonusPerLevel;
  final PrestigeEffectKind effect;

  const PrestigeUpgradeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.accent,
    required this.baseCost,
    required this.growth,
    required this.bonusPerLevel,
    required this.effect,
  });

  int costForLevel(int level) {
    var v = baseCost.toDouble();
    for (var i = 0; i < level; i++) {
      v *= growth;
    }
    return v.ceil();
  }
}
