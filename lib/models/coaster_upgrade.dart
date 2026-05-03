import 'package:flutter/material.dart';

class TapUpgradeDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color accent;
  final double baseCost;
  final double tapPowerPerLevel;

  const TapUpgradeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.accent,
    required this.baseCost,
    required this.tapPowerPerLevel,
  });

  /// price = baseCost × 1.10^level
  double costForLevel(int level) =>
      baseCost * _pow(1.10, level);

  static double _pow(double base, int exp) {
    var v = 1.0;
    for (var i = 0; i < exp; i++) {
      v *= base;
    }
    return v;
  }
}
