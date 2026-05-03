import 'package:flutter/material.dart';

enum PartRarity { n, r, sr, ssr, lr, ur }

extension PartRarityX on PartRarity {
  String get label {
    switch (this) {
      case PartRarity.n:
        return 'N';
      case PartRarity.r:
        return 'R';
      case PartRarity.sr:
        return 'SR';
      case PartRarity.ssr:
        return 'SSR';
      case PartRarity.lr:
        return 'LR';
      case PartRarity.ur:
        return 'UR';
    }
  }

  Color get color {
    switch (this) {
      case PartRarity.n:
        return const Color(0xFFB0BEC5);
      case PartRarity.r:
        return const Color(0xFF81D4FA);
      case PartRarity.sr:
        return const Color(0xFFB39DDB);
      case PartRarity.ssr:
        return const Color(0xFFFFB74D);
      case PartRarity.lr:
        return const Color(0xFFFF8A65);
      case PartRarity.ur:
        return const Color(0xFFFFD54F);
    }
  }

  bool get isSrPlus => index >= PartRarity.sr.index;
}

enum PartSlot { train, rail, station, staff, guest, effect }

class CoasterPartDef {
  final String id;
  final String name;
  final String setId;
  final PartSlot slot;
  final PartRarity rarity;
  final IconData icon;
  // Bonuses applied per copy owned (additive fractions).
  final double tapBonus;
  final double cpsBonus;
  final double goldenChanceBonus;

  const CoasterPartDef({
    required this.id,
    required this.name,
    required this.setId,
    required this.slot,
    required this.rarity,
    required this.icon,
    this.tapBonus = 0,
    this.cpsBonus = 0,
    this.goldenChanceBonus = 0,
  });
}

class CoasterSetDef {
  final String id;
  final String name;
  final Color accent;
  final List<String> partIds;
  // bonuses keyed by number of pieces owned (>= count): each is additive
  final Map<int, double> tapBonus;
  final Map<int, double> cpsBonus;
  final Map<int, double> overallBonus;

  const CoasterSetDef({
    required this.id,
    required this.name,
    required this.accent,
    required this.partIds,
    this.tapBonus = const <int, double>{},
    this.cpsBonus = const <int, double>{},
    this.overallBonus = const <int, double>{},
  });
}
