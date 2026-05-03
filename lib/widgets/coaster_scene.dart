import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/game_provider.dart';

/// Animated 2.5D-ish roller-coaster scene rendered with CustomPainter.
class CoasterScene extends ConsumerStatefulWidget {
  const CoasterScene({super.key});

  @override
  ConsumerState<CoasterScene> createState() => _CoasterSceneState();
}

class _CoasterSceneState extends ConsumerState<CoasterScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bg;

  @override
  void initState() {
    super.initState();
    _bg = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _bg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    return AnimatedBuilder(
      animation: _bg,
      builder: (_, __) {
        return CustomPaint(
          painter: _CoasterPainter(
            phase: game.ride.phase,
            phaseT: _phaseProgress(game.ride),
            stage: game.coasterStage,
            seated: game.ride.seatedCount,
            queue: game.ride.queueCount,
            time: DateTime.now().millisecondsSinceEpoch / 1000.0,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }

  double _phaseProgress(RideState r) {
    final ms = r.phaseDuration.inMilliseconds;
    if (ms <= 0) return 1;
    return (r.phaseElapsed.inMilliseconds / ms).clamp(0, 1);
  }
}

class _CoasterPainter extends CustomPainter {
  final RidePhase phase;
  final double phaseT;
  final int stage;
  final int seated;
  final int queue;
  final double time;

  _CoasterPainter({
    required this.phase,
    required this.phaseT,
    required this.stage,
    required this.seated,
    required this.queue,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawHills(canvas, size);
    _drawTrack(canvas, size);
    _drawStation(canvas, size);
    _drawQueue(canvas, size);
    _drawTrain(canvas, size);
    _drawDecorations(canvas, size);
  }

  void _drawSky(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB3E5FC), Color(0xFFFFCCBC)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    // Slow clouds
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final w = size.width;
    final cloudY = size.height * 0.18;
    for (var i = 0; i < 3; i++) {
      final x =
          (((time * 6 + i * w / 3) % (w + 100)) - 50);
      _drawCloud(canvas, Offset(x, cloudY + i * 8), 26 + i * 4.0, cloud);
    }
  }

  void _drawCloud(Canvas canvas, Offset c, double r, Paint p) {
    canvas.drawCircle(c, r, p);
    canvas.drawCircle(c.translate(r * 0.7, 4), r * 0.8, p);
    canvas.drawCircle(c.translate(-r * 0.7, 4), r * 0.8, p);
  }

  void _drawHills(Canvas canvas, Size size) {
    final hill = Paint()..color = const Color(0xFFC5E1A5);
    final hill2 = Paint()..color = const Color(0xFFAED581);
    final path1 = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.35,
        size.width * 0.5,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.65,
        size.width,
        size.height * 0.45,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path1, hill);

    final path2 = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.55,
        size.width * 0.5,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.85,
        size.width,
        size.height * 0.7,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, hill2);
  }

  void _drawTrack(Canvas canvas, Size size) {
    // Big arc-shaped track
    final railColor = stage >= 6 ? const Color(0xFFEC407A) : AppColors.railWood;
    final pillarColor = const Color(0xFF8D6E63);

    final pillar = Paint()..color = pillarColor;
    for (var i = 1; i < 5; i++) {
      final x = size.width * (i / 5);
      final yTop = _trackY(x / size.width) * size.height;
      canvas.drawRect(
        Rect.fromLTWH(x - 4, yTop, 8, size.height - yTop - 80),
        pillar,
      );
    }

    final rail = Paint()
      ..color = railColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final steps = 60;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = size.width * t;
      final y = _trackY(t) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, rail);

    // Cross ties (rungs)
    final tie = Paint()
      ..color = railColor.withValues(alpha: 0.6)
      ..strokeWidth = 3;
    for (var i = 1; i < steps; i += 3) {
      final t = i / steps;
      final x = size.width * t;
      final y = _trackY(t) * size.height;
      canvas.drawLine(Offset(x, y), Offset(x, y + 10), tie);
    }
  }

  double _trackY(double t) {
    // Sinusoidal track that creates a fun coaster-like curve.
    final base = 0.55;
    final amp = 0.18;
    return base - amp * math.sin(t * math.pi * 1.3);
  }

  void _drawStation(Canvas canvas, Size size) {
    final stX = size.width * 0.05;
    final stY = _trackY(0.0) * size.height - 28;
    final stW = size.width * 0.18;
    final stH = 60.0;

    final roof = Paint()..color = const Color(0xFFFF8A65);
    final wall = Paint()..color = const Color(0xFFFFE0B2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(stX, stY + 14, stW, stH),
        const Radius.circular(8),
      ),
      wall,
    );
    final roofPath = Path()
      ..moveTo(stX - 6, stY + 18)
      ..lineTo(stX + stW / 2, stY - 2)
      ..lineTo(stX + stW + 6, stY + 18)
      ..close();
    canvas.drawPath(roofPath, roof);

    final flag = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawRect(
      Rect.fromLTWH(stX + stW / 2 - 1, stY - 18, 2, 18),
      Paint()..color = Colors.brown,
    );
    canvas.drawPath(
      Path()
        ..moveTo(stX + stW / 2, stY - 18)
        ..lineTo(stX + stW / 2 + 12, stY - 14)
        ..lineTo(stX + stW / 2, stY - 10)
        ..close(),
      flag,
    );

    // Conductor stick figure waving
    final conductor = stX + stW + 6;
    final pY = stY + stH - 18;
    final tone = Paint()..color = const Color(0xFFFFCC80);
    canvas.drawCircle(Offset(conductor, pY), 4, tone);
    canvas.drawLine(Offset(conductor, pY + 4),
        Offset(conductor, pY + 12), Paint()..color = const Color(0xFF6D4C41)..strokeWidth = 2);
    final waveAmp = math.sin(time * 4) * 4;
    canvas.drawLine(
      Offset(conductor, pY + 6),
      Offset(conductor + 6, pY + 2 + waveAmp),
      Paint()..color = const Color(0xFFFFCC80)..strokeWidth = 2,
    );
  }

  void _drawQueue(Canvas canvas, Size size) {
    if (queue == 0 && phase == RidePhase.waitingForGuests) return;
    final stX = size.width * 0.05;
    final stY = _trackY(0.0) * size.height + 50;
    final colors = [
      const Color(0xFFEF9A9A),
      const Color(0xFF80CBC4),
      const Color(0xFFFFCC80),
      const Color(0xFF90CAF9),
      const Color(0xFFCE93D8),
      const Color(0xFFA5D6A7),
      const Color(0xFFFFAB91),
      const Color(0xFFB39DDB),
    ];
    final n = queue.clamp(0, 8);
    for (var i = 0; i < n; i++) {
      final cx = stX + 10 + i * 9.0;
      final bob = math.sin(time * 4 + i) * 1.2;
      final c = colors[i % colors.length];
      canvas.drawCircle(Offset(cx, stY + bob), 4, Paint()..color = c);
      canvas.drawRect(
        Rect.fromLTWH(cx - 3, stY + 4 + bob, 6, 8),
        Paint()..color = c,
      );
    }
  }

  void _drawTrain(Canvas canvas, Size size) {
    final t = _trainPosition();
    final x = size.width * t;
    final y = _trackY(t) * size.height - 14;

    // Train body
    final bodyColor = _trainColor();
    final body = Paint()..color = bodyColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 22, y - 12, 44, 20),
        const Radius.circular(8),
      ),
      body,
    );
    // Windows
    final win = Paint()..color = const Color(0xFFFFFDE7);
    final showSeats = phase != RidePhase.waitingForGuests;
    final personPaint = Paint()..color = const Color(0xFFFFCC80);
    for (var i = 0; i < 3; i++) {
      final wx = x - 18 + i * 14.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, y - 9, 10, 10),
          const Radius.circular(3),
        ),
        win,
      );
      if (showSeats && seated > i) {
        canvas.drawCircle(Offset(wx + 5, y - 4), 3, personPaint);
      }
    }
    // Wheels
    final wheel = Paint()..color = const Color(0xFF455A64);
    canvas.drawCircle(Offset(x - 14, y + 10), 4, wheel);
    canvas.drawCircle(Offset(x + 14, y + 10), 4, wheel);
    // Front nose / safety bar indicator
    if (phase == RidePhase.safetyBar ||
        phase == RidePhase.ready ||
        phase == RidePhase.riding ||
        phase == RidePhase.arriving) {
      final bar = Paint()..color = const Color(0xFFEC407A)..strokeWidth = 2;
      canvas.drawLine(
        Offset(x - 18, y - 2),
        Offset(x + 18, y - 2),
        bar,
      );
    }
    // Speed lines while riding
    if (phase == RidePhase.riding) {
      final line = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 2;
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(
          Offset(x - 28 - i * 6, y - 4 + i * 2.0),
          Offset(x - 18 - i * 6, y - 4 + i * 2.0),
          line,
        );
      }
    }
  }

  Color _trainColor() {
    switch (stage) {
      case 0:
        return const Color(0xFFA1887F);
      case 1:
        return const Color(0xFFFFAB91);
      case 2:
        return const Color(0xFFFFB74D);
      case 3:
        return const Color(0xFF81D4FA);
      case 4:
        return const Color(0xFFCE93D8);
      case 5:
        return const Color(0xFFEF5350);
      case 6:
        return const Color(0xFFEC407A);
      case 7:
        return const Color(0xFFB39DDB);
      case 8:
        return const Color(0xFFFFD54F);
      default:
        return const Color(0xFF8E24AA);
    }
  }

  /// 0..1 position along the track per phase.
  double _trainPosition() {
    switch (phase) {
      case RidePhase.waitingForGuests:
      case RidePhase.boarding:
      case RidePhase.seating:
      case RidePhase.safetyBar:
        return 0.10;
      case RidePhase.ready:
        return 0.10 + 0.04 * phaseT;
      case RidePhase.riding:
        return 0.14 + 0.78 * phaseT;
      case RidePhase.arriving:
        return 0.92 + 0.06 * phaseT;
      case RidePhase.unboarding:
        // Snap back to station for next cycle visually
        return 0.10;
    }
  }

  void _drawDecorations(Canvas canvas, Size size) {
    if (stage >= 6) {
      // Fireworks at later stages
      final c = Offset(size.width * 0.85, size.height * 0.22);
      final paint = Paint()
        ..color = const Color(0xFFFFCA28).withValues(alpha: 0.9)
        ..strokeWidth = 2;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + time * 0.5;
        canvas.drawLine(
          c,
          c.translate(math.cos(a) * (8 + math.sin(time * 4) * 4),
              math.sin(a) * (8 + math.sin(time * 4) * 4)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CoasterPainter old) =>
      old.phase != phase ||
      old.phaseT != phaseT ||
      old.stage != stage ||
      old.seated != seated ||
      old.queue != queue ||
      old.time != time;
}
