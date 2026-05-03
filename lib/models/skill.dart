import 'package:flutter/material.dart';

enum SkillKind {
  turboBurst,      // current CPS × 300s instantly
  comboSurge,      // for N seconds: combo gain x2, tap reward x2
  essenceGather,   // gain N essence
  autoTap,         // for N seconds: auto-tap every 250ms
  rushBooster,     // for N seconds: tap+cps × 3
  callQueue,       // refill queue immediately
  goldenSummon,    // spawn golden guest immediately
}

class SkillDef {
  final String id;
  final String name;
  final String description;
  final SkillKind kind;
  final IconData icon;
  final Color accent;
  final Duration cooldown;
  final Duration duration;
  final double amount;

  const SkillDef({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.icon,
    required this.accent,
    required this.cooldown,
    this.duration = Duration.zero,
    this.amount = 0,
  });
}
