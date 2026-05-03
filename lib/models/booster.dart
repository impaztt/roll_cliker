enum BoosterKind { cps, tap, rush }

class BoosterDef {
  final String id;
  final String name;
  final String description;
  final BoosterKind kind;
  final double multiplier;
  final Duration duration;
  final int essenceCost;

  const BoosterDef({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.multiplier,
    required this.duration,
    required this.essenceCost,
  });
}

class ActiveBooster {
  final String id;
  final BoosterKind kind;
  final double multiplier;
  final DateTime expiresAt;

  ActiveBooster({
    required this.id,
    required this.kind,
    required this.multiplier,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.name,
        'multiplier': multiplier,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory ActiveBooster.fromJson(Map<String, dynamic> json) => ActiveBooster(
        id: json['id'] as String,
        kind: BoosterKind.values.firstWhere(
          (k) => k.name == (json['kind'] as String? ?? 'cps'),
          orElse: () => BoosterKind.cps,
        ),
        multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1,
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
