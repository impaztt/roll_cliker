import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_provider.dart';

/// Top-down isometric (2.5D) diorama of the coaster park.
/// Designed to fit the entire ride loop on a single screen so the player
/// can watch it from a fixed pulled-back camera.
class CoasterScene extends ConsumerStatefulWidget {
  const CoasterScene({super.key});

  @override
  ConsumerState<CoasterScene> createState() => _CoasterSceneState();
}

class _CoasterSceneState extends ConsumerState<CoasterScene>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker((_) {
      setState(() {
        _t = DateTime.now().millisecondsSinceEpoch / 1000.0;
      });
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    return RepaintBoundary(
      child: CustomPaint(
        painter: _DioramaPainter(
          phase: game.ride.phase,
          phaseT: _phaseProgress(game.ride),
          stage: game.coasterStage,
          seated: game.ride.seatedCount,
          queue: game.ride.queueCount,
          carsLevel: game.data.carsLevel,
          time: _t,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  double _phaseProgress(RideState r) {
    final ms = r.phaseDuration.inMilliseconds;
    if (ms <= 0) return 1;
    return (r.phaseElapsed.inMilliseconds / ms).clamp(0, 1);
  }
}

/// Lightweight Ticker that mimics SchedulerBinding's vsync without needing
/// to import `package:flutter/scheduler.dart`.
class Ticker {
  final void Function(Duration) onTick;
  bool _running = false;
  Ticker(this.onTick);
  void start() {
    _running = true;
    _loop();
  }

  Future<void> _loop() async {
    while (_running) {
      await Future<void>.delayed(const Duration(milliseconds: 33));
      if (_running) onTick(Duration.zero);
    }
  }

  void dispose() {
    _running = false;
  }
}

// ─────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────

class _DioramaPainter extends CustomPainter {
  final RidePhase phase;
  final double phaseT;
  final int stage;
  final int seated;
  final int queue;
  final int carsLevel;
  final double time;

  _DioramaPainter({
    required this.phase,
    required this.phaseT,
    required this.stage,
    required this.seated,
    required this.queue,
    required this.carsLevel,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final palette = _PaletteForStage.forStage(stage);

    _drawBackground(canvas, size, palette);

    // Center the scene so that grid (0,0) sits in the middle horizontally
    // and slightly above the bottom.
    final cx = size.width / 2;
    final cy = size.height * 0.46;
    final scale = math.min(size.width / 11.0, size.height / 14.0);

    final ctx = _SceneCtx(
      canvas: canvas,
      size: size,
      cx: cx,
      cy: cy,
      scale: scale,
      time: time,
      palette: palette,
    );

    _drawGround(ctx);
    _drawSurroundings(ctx);
    _drawTrack(ctx);
    _drawStation(ctx);
    _drawQueue(ctx);
    _drawTrain(ctx);
    _drawSparkles(ctx);
  }

  // ── Coordinate helper ────────────────────────────────────────────────
  // Convert world (x, y, z) to screen. y is depth, z is height.
  Offset _world(_SceneCtx ctx, double x, double y, [double z = 0]) {
    // Classic 2:1 isometric.
    final sx = ctx.cx + (x - y) * ctx.scale * 0.86;
    final sy = ctx.cy + (x + y) * ctx.scale * 0.5 - z * ctx.scale * 0.9;
    return Offset(sx, sy);
  }

  // ── Background sky/grass split ──────────────────────────────────────
  void _drawBackground(Canvas canvas, Size size, _StagePalette palette) {
    final rect = Offset.zero & size;
    final skyShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [palette.skyTop, palette.skyBot],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = skyShader);
  }

  void _drawGround(_SceneCtx ctx) {
    // Lawn rhombus
    final corners = <Offset>[
      _world(ctx, -5, -5),
      _world(ctx, 5, -5),
      _world(ctx, 5, 5),
      _world(ctx, -5, 5),
    ];
    final path = Path()..addPolygon(corners, true);
    final lawn = Paint()..color = ctx.palette.grass;
    ctx.canvas.drawPath(path, lawn);

    // Lawn highlight (lighter band)
    final lawnHi = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final hiPath = Path()
      ..addPolygon([
        _world(ctx, -5, -5),
        _world(ctx, 5, -5),
        _world(ctx, 5, -2),
        _world(ctx, -5, -2),
      ], true);
    ctx.canvas.drawPath(hiPath, lawnHi);

    // Outer asphalt frame
    final asphaltPaint = Paint()..color = const Color(0xFFCFD8DC);
    final outer = <Offset>[
      _world(ctx, -6.4, -6.4),
      _world(ctx, 6.4, -6.4),
      _world(ctx, 6.4, 6.4),
      _world(ctx, -6.4, 6.4),
    ];
    final inner = <Offset>[
      _world(ctx, -5, -5),
      _world(ctx, 5, -5),
      _world(ctx, 5, 5),
      _world(ctx, -5, 5),
    ];
    final road = Path()
      ..addPolygon(outer, true)
      ..addPolygon(inner.reversed.toList(), true)
      ..fillType = PathFillType.evenOdd;
    ctx.canvas.drawPath(road, asphaltPaint);

    // Crosswalk in the front
    final cross = Paint()..color = Colors.white.withValues(alpha: 0.8);
    for (var i = 0; i < 5; i++) {
      final x0 = -1.4 + i * 0.6;
      final p = Path()
        ..addPolygon([
          _world(ctx, x0, 5.1),
          _world(ctx, x0 + 0.4, 5.1),
          _world(ctx, x0 + 0.4, 6.2),
          _world(ctx, x0, 6.2),
        ], true);
      ctx.canvas.drawPath(p, cross);
    }
  }

  // ── Surroundings (cute dioramas around the lawn) ────────────────────
  void _drawSurroundings(_SceneCtx ctx) {
    // Left building (food shop)
    _drawBox(ctx,
        x: -6.0,
        y: -4.5,
        w: 1.6,
        d: 1.6,
        h: 1.6,
        wall: const Color(0xFFFFF1D6),
        roof: const Color(0xFFEF7F6F));
    // Awning stripes
    final awnRect = <Offset>[
      _world(ctx, -6.0, -4.5, 0.7),
      _world(ctx, -4.4, -4.5, 0.7),
      _world(ctx, -4.4, -4.5, 0.95),
      _world(ctx, -6.0, -4.5, 0.95),
    ];
    ctx.canvas.drawPath(
      Path()..addPolygon(awnRect, true),
      Paint()..color = const Color(0xFFFF6F60),
    );

    // Tree
    _drawTree(ctx, -3.6, -5.6);
    _drawTree(ctx, 4.5, -5.6);
    _drawTree(ctx, -5.5, 4.0);
    _drawTree(ctx, 5.4, 3.4);

    // Right pavilion (balloon stand)
    _drawBox(ctx,
        x: 4.4,
        y: -4.4,
        w: 1.4,
        d: 1.4,
        h: 1.0,
        wall: const Color(0xFFB3E5FC),
        roof: const Color(0xFF4FC3F7));
    _drawBalloon(ctx, x: 4.0, y: -4.4, color: const Color(0xFFEF9A9A));
    _drawBalloon(ctx, x: 5.6, y: -4.4, color: const Color(0xFFFFD54F));
    _drawBalloon(ctx, x: 4.8, y: -3.4, color: const Color(0xFF80CBC4));

    // Food truck (front-right)
    _drawBox(ctx,
        x: 4.2,
        y: 3.2,
        w: 1.6,
        d: 0.9,
        h: 0.9,
        wall: const Color(0xFFFFE082),
        roof: const Color(0xFFEF5350));
    // wheels
    final wheelP = Paint()..color = const Color(0xFF263238);
    ctx.canvas.drawCircle(_world(ctx, 4.4, 3.6, 0), 4, wheelP);
    ctx.canvas.drawCircle(_world(ctx, 5.6, 3.6, 0), 4, wheelP);

    // Gate poles
    _drawPole(ctx, -4.5, 5.0, ctx.palette.poleColor);
    _drawPole(ctx, 4.5, 5.0, ctx.palette.poleColor);
  }

  void _drawTree(_SceneCtx ctx, double x, double y) {
    // Trunk
    final trunkTop = _world(ctx, x, y, 0.5);
    final trunkBot = _world(ctx, x, y, 0);
    ctx.canvas.drawLine(
      trunkBot,
      trunkTop,
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..strokeWidth = 4,
    );
    // Foliage (3 stacked discs for low-poly tree)
    void disc(double z, double r, Color c) {
      ctx.canvas.drawOval(
        Rect.fromCenter(
            center: _world(ctx, x, y, z), width: r * 2, height: r * 1.2),
        Paint()..color = c,
      );
    }

    disc(0.6, 12, const Color(0xFF66BB6A));
    disc(0.85, 10, const Color(0xFF81C784));
    disc(1.05, 7, const Color(0xFFA5D6A7));
  }

  void _drawBalloon(_SceneCtx ctx, {required double x, required double y, required Color color}) {
    final base = _world(ctx, x, y, 0);
    final body = _world(ctx, x, y, 1.4);
    ctx.canvas.drawLine(
      base,
      body,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..strokeWidth = 1,
    );
    ctx.canvas.drawCircle(body, 8, Paint()..color = color);
    ctx.canvas.drawCircle(
      body.translate(-2, -2),
      2,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  void _drawPole(_SceneCtx ctx, double x, double y, Color color) {
    final base = _world(ctx, x, y, 0);
    final top = _world(ctx, x, y, 1.2);
    ctx.canvas.drawLine(
      base,
      top,
      Paint()
        ..color = color
        ..strokeWidth = 3,
    );
    ctx.canvas.drawCircle(top, 4, Paint()..color = const Color(0xFFFFCA28));
  }

  /// Draws an isometric box (cuboid) by painting top + two visible faces.
  void _drawBox(
    _SceneCtx ctx, {
    required double x,
    required double y,
    required double w,
    required double d,
    required double h,
    required Color wall,
    required Color roof,
  }) {
    // 8 corners (top-of-floor `bXX` and roof `tXX`).
    final btr = _world(ctx, x + w, y, 0);
    final bbr = _world(ctx, x + w, y + d, 0);
    final bbl = _world(ctx, x, y + d, 0);
    final ttl = _world(ctx, x, y, h);
    final ttr = _world(ctx, x + w, y, h);
    final tbr = _world(ctx, x + w, y + d, h);
    final tbl = _world(ctx, x, y + d, h);

    // Right wall (lighter)
    final rightFace = Path()..addPolygon([btr, bbr, tbr, ttr], true);
    ctx.canvas.drawPath(rightFace, Paint()..color = _shade(wall, -0.05));

    // Front wall (darker)
    final frontFace = Path()..addPolygon([bbl, bbr, tbr, tbl], true);
    ctx.canvas.drawPath(frontFace, Paint()..color = _shade(wall, -0.18));

    // Roof / top
    final top = Path()..addPolygon([ttl, ttr, tbr, tbl], true);
    ctx.canvas.drawPath(top, Paint()..color = roof);

    // Door
    final doorW = w * 0.25;
    final doorH = h * 0.55;
    final dxl = x + w * 0.5 - doorW / 2;
    final dxr = dxl + doorW;
    final door = Path()
      ..addPolygon([
        _world(ctx, dxl, y + d, 0),
        _world(ctx, dxr, y + d, 0),
        _world(ctx, dxr, y + d, doorH),
        _world(ctx, dxl, y + d, doorH),
      ], true);
    ctx.canvas.drawPath(door, Paint()..color = const Color(0xFF6D4C41));
  }

  // ── Track loop ──────────────────────────────────────────────────────
  // The ride uses a closed loop sampled into points. We keep this
  // outside the painter as a static so all calls share the same shape.
  static const int _trackSamples = 220;
  static List<_Vec3>? _trackPoints;

  static List<_Vec3> _track() {
    if (_trackPoints != null) return _trackPoints!;
    final pts = <_Vec3>[];
    for (var i = 0; i < _trackSamples; i++) {
      final t = i / _trackSamples;
      final a = t * math.pi * 2;
      // Figure-eight-ish loop with a bump in the middle.
      final r1 = 3.0;
      final r2 = 2.2;
      final x = r1 * math.sin(a);
      final y = r2 * math.sin(a * 2) * 0.7 - 1.0; // center the loop slightly back
      // Height undulation creates the "hill + dip" feel.
      final z = 0.55 + 0.45 * (math.sin(a * 2 + 0.6) * 0.5 + 0.5);
      pts.add(_Vec3(x, y, z));
    }
    _trackPoints = pts;
    return pts;
  }

  void _drawTrack(_SceneCtx ctx) {
    final pts = _track();
    final railColor = ctx.palette.railColor;
    final beamColor = ctx.palette.beamColor;

    // Pillars at regular intervals.
    for (var i = 0; i < pts.length; i += 14) {
      final p = pts[i];
      final base = _world(ctx, p.x, p.y, 0);
      final top = _world(ctx, p.x, p.y, p.z);
      ctx.canvas.drawLine(
        base,
        top,
        Paint()
          ..color = beamColor
          ..strokeWidth = 4,
      );
    }

    // Two parallel rails (separated horizontally in screen-space).
    Path railPath(double offset) {
      final p = Path();
      for (var i = 0; i <= pts.length; i++) {
        final v = pts[i % pts.length];
        final s = _world(ctx, v.x, v.y, v.z);
        final s2 = s.translate(offset, 0);
        if (i == 0) {
          p.moveTo(s2.dx, s2.dy);
        } else {
          p.lineTo(s2.dx, s2.dy);
        }
      }
      return p;
    }

    final railPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = railColor;
    ctx.canvas.drawPath(railPath(-3), railPaint);
    ctx.canvas.drawPath(railPath(3), railPaint);

    // Cross ties (rungs).
    final tiePaint = Paint()
      ..color = beamColor
      ..strokeWidth = 2;
    for (var i = 0; i < pts.length; i += 4) {
      final v = pts[i];
      final s = _world(ctx, v.x, v.y, v.z);
      ctx.canvas.drawLine(
        s.translate(-3, 0),
        s.translate(3, 0),
        tiePaint,
      );
    }
  }

  // ── Station ─────────────────────────────────────────────────────────
  void _drawStation(_SceneCtx ctx) {
    // Big station box with a checkered roof, sitting at the front of
    // the loop so it's clearly visible.
    final wall = const Color(0xFFB3E5FC);
    _drawBox(ctx,
        x: -2.0,
        y: 1.4,
        w: 4.0,
        d: 1.6,
        h: 1.4,
        wall: wall,
        roof: const Color(0xFF4FC3F7));
    // Roof checker pattern (lighter rectangles)
    final t = const Color(0xFFE1F5FE);
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 2; j++) {
        if ((i + j) % 2 != 0) continue;
        final x0 = -2.0 + 0.3 + i * 1.2;
        final y0 = 1.4 + 0.3 + j * 0.65;
        final p = Path()
          ..addPolygon([
            _world(ctx, x0, y0, 1.42),
            _world(ctx, x0 + 1.0, y0, 1.42),
            _world(ctx, x0 + 1.0, y0 + 0.5, 1.42),
            _world(ctx, x0, y0 + 0.5, 1.42),
          ], true);
        ctx.canvas.drawPath(p, Paint()..color = t);
      }
    }

    // Counter signage on the front of the station.
    final seats = seatsForLevel(carsLevel);
    final qCap = queueCapacityForLevel(carsLevel);
    _drawSignBoard(ctx, x: -1.7, y: 3.0, label: '$seated/$seats',
        color: const Color(0xFF2196F3));
    _drawSignBoard(ctx, x: 0.8, y: 3.0, label: '$queue/$qCap',
        color: const Color(0xFF9C27B0));

    // Conductor
    _drawCharacter(ctx, x: 1.7, y: 1.6,
        shirt: const Color(0xFFE53935),
        pants: const Color(0xFF1565C0),
        skin: const Color(0xFFFFCC80),
        wave: math.sin(time * 4) * 4);
  }

  void _drawSignBoard(
    _SceneCtx ctx, {
    required double x,
    required double y,
    required String label,
    required Color color,
  }) {
    final bottom = _world(ctx, x, y, 0);
    final top = _world(ctx, x, y, 0.85);
    ctx.canvas.drawLine(
      bottom,
      top,
      Paint()
        ..color = const Color(0xFF455A64)
        ..strokeWidth = 2,
    );
    final boardCenter = _world(ctx, x, y, 1.05);
    final rect = Rect.fromCenter(center: boardCenter, width: 50, height: 30);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    ctx.canvas.drawRRect(rrect, Paint()..color = color);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      ctx.canvas,
      rect.center.translate(-tp.width / 2, -tp.height / 2),
    );
  }

  // ── Queue ───────────────────────────────────────────────────────────
  void _drawQueue(_SceneCtx ctx) {
    if (queue == 0 && phase == RidePhase.waitingForGuests) return;
    final palette = <Color>[
      const Color(0xFFEF9A9A),
      const Color(0xFF80CBC4),
      const Color(0xFFFFCC80),
      const Color(0xFF90CAF9),
      const Color(0xFFCE93D8),
      const Color(0xFFA5D6A7),
      const Color(0xFFFFAB91),
      const Color(0xFFB39DDB),
    ];
    final pants = const Color(0xFF455A64);
    final n = queue.clamp(0, 14);
    for (var i = 0; i < n; i++) {
      // Guests stretch from the crosswalk back to the station entrance.
      final progress = i / (n - 1).clamp(1, 999);
      final y = 5.4 - progress * 2.0;
      final x = -2.6 + (i % 2 == 0 ? -0.2 : 0.2);
      final shirt = palette[i % palette.length];
      _drawCharacter(ctx,
          x: x,
          y: y,
          shirt: shirt,
          pants: pants,
          skin: const Color(0xFFFFCC80),
          wave: 0,
          bob: math.sin(time * 4 + i) * 0.6);
    }
  }

  // ── Train ───────────────────────────────────────────────────────────
  /// Returns 0..1 position around the track loop based on ride phase.
  double _trainTrackT() {
    switch (phase) {
      case RidePhase.waitingForGuests:
      case RidePhase.boarding:
      case RidePhase.seating:
      case RidePhase.safetyBar:
        return 0.0;
      case RidePhase.ready:
        return 0.02 * phaseT;
      case RidePhase.riding:
        return 0.02 + 0.96 * phaseT;
      case RidePhase.arriving:
        return 0.98 + 0.02 * phaseT;
      case RidePhase.unboarding:
        return 0.0;
    }
  }

  void _drawTrain(_SceneCtx ctx) {
    final pts = _track();
    final tT = _trainTrackT();
    final cars = carsLevel.clamp(1, 8);
    final spacing = 0.012;

    // Draw multiple cars trailing behind the head.
    for (var c = 0; c < cars; c++) {
      final t = (tT - c * spacing + 1) % 1;
      final i = (t * pts.length).floor() % pts.length;
      final iNext = (i + 1) % pts.length;
      final v = pts[i];
      final v2 = pts[iNext];
      final p = _world(ctx, v.x, v.y, v.z);
      final p2 = _world(ctx, v2.x, v2.y, v2.z);
      _drawCar(ctx, p, p2, c == 0);
    }
  }

  void _drawCar(_SceneCtx ctx, Offset p, Offset pNext, bool head) {
    final dir = pNext - p;
    final ang = math.atan2(dir.dy, dir.dx);
    ctx.canvas.save();
    ctx.canvas.translate(p.dx, p.dy);
    ctx.canvas.rotate(ang);

    final body = _carColor();
    final shadowP = Paint()..color = Colors.black.withValues(alpha: 0.18);
    ctx.canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 12), width: 28, height: 8),
      shadowP,
    );
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 0), width: 28, height: 16),
      const Radius.circular(6),
    );
    ctx.canvas.drawRRect(bodyRect, Paint()..color = body);
    // Car roof highlight
    ctx.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -3), width: 24, height: 6),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );
    // Two seated passengers if they're aboard
    final showSeats = phase == RidePhase.safetyBar ||
        phase == RidePhase.ready ||
        phase == RidePhase.riding ||
        phase == RidePhase.arriving;
    if (showSeats && seated > 0) {
      final headPaint = Paint()..color = const Color(0xFFFFCC80);
      ctx.canvas.drawCircle(const Offset(-6, -2), 3, headPaint);
      ctx.canvas.drawCircle(const Offset(6, -2), 3, headPaint);
      ctx.canvas.drawRect(
        Rect.fromCenter(center: const Offset(-6, 2), width: 6, height: 5),
        Paint()..color = const Color(0xFF42A5F5),
      );
      ctx.canvas.drawRect(
        Rect.fromCenter(center: const Offset(6, 2), width: 6, height: 5),
        Paint()..color = const Color(0xFFEF5350),
      );
    }
    if (head) {
      // headlight
      ctx.canvas.drawCircle(
        const Offset(14, 0),
        2.5,
        Paint()..color = const Color(0xFFFFD54F),
      );
    }
    ctx.canvas.restore();
  }

  Color _carColor() {
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
        return const Color(0xFFAB47BC);
    }
  }

  // ── Tiny humanoid character ─────────────────────────────────────────
  void _drawCharacter(_SceneCtx ctx,
      {required double x,
      required double y,
      required Color shirt,
      required Color pants,
      required Color skin,
      double wave = 0,
      double bob = 0}) {
    final feet = _world(ctx, x, y, 0).translate(0, -bob);
    final hip = _world(ctx, x, y, 0.30).translate(0, -bob);
    final chest = _world(ctx, x, y, 0.55).translate(0, -bob);
    final head = _world(ctx, x, y, 0.78).translate(0, -bob);

    // Shadow
    ctx.canvas.drawOval(
      Rect.fromCenter(center: feet.translate(0, 2), width: 10, height: 4),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    // Pants
    ctx.canvas.drawLine(
      feet,
      hip,
      Paint()
        ..color = pants
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // Shirt body
    ctx.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset((hip.dx + chest.dx) / 2, (hip.dy + chest.dy) / 2),
            width: 8,
            height: 12),
        const Radius.circular(3),
      ),
      Paint()..color = shirt,
    );
    // Arms
    final armPaint = Paint()
      ..color = shirt
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    ctx.canvas.drawLine(
      chest.translate(-3, 0),
      chest.translate(-5, 4),
      armPaint,
    );
    ctx.canvas.drawLine(
      chest.translate(3, 0),
      chest.translate(5 + wave, 4 - wave),
      armPaint,
    );
    // Head
    ctx.canvas.drawCircle(head, 4, Paint()..color = skin);
    // Hair (a small dark cap)
    ctx.canvas.drawArc(
      Rect.fromCenter(center: head.translate(0, -1), width: 8, height: 8),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFF6D4C41),
    );
  }

  // ── Sparkles for high stages ────────────────────────────────────────
  void _drawSparkles(_SceneCtx ctx) {
    if (stage < 6) return;
    final p = Paint()..color = const Color(0xFFFFCA28);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + time * 0.6;
      final r = 6 + 4 * math.sin(time * 3 + i);
      final c = _world(ctx, 0, -2.5, 1.6);
      ctx.canvas.drawCircle(
        c.translate(math.cos(a) * 30, math.sin(a) * 14),
        r * 0.4,
        p,
      );
    }
  }

  static Color _shade(Color base, double pct) {
    final hsl = HSLColor.fromColor(base);
    final l = (hsl.lightness + pct).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }

  @override
  bool shouldRepaint(covariant _DioramaPainter old) =>
      old.phase != phase ||
      old.phaseT != phaseT ||
      old.stage != stage ||
      old.seated != seated ||
      old.queue != queue ||
      old.carsLevel != carsLevel ||
      old.time != time;
}

class _SceneCtx {
  final Canvas canvas;
  final Size size;
  final double cx;
  final double cy;
  final double scale;
  final double time;
  final _StagePalette palette;
  _SceneCtx({
    required this.canvas,
    required this.size,
    required this.cx,
    required this.cy,
    required this.scale,
    required this.time,
    required this.palette,
  });
}

class _Vec3 {
  final double x, y, z;
  const _Vec3(this.x, this.y, this.z);
}

// ── Per-stage palette ──────────────────────────────────────────────────
class _StagePalette {
  final Color skyTop;
  final Color skyBot;
  final Color grass;
  final Color railColor;
  final Color beamColor;
  final Color poleColor;
  const _StagePalette({
    required this.skyTop,
    required this.skyBot,
    required this.grass,
    required this.railColor,
    required this.beamColor,
    required this.poleColor,
  });
}

class _PaletteForStage {
  static _StagePalette forStage(int stage) {
    switch (stage) {
      case 0:
      case 1:
        return const _StagePalette(
          skyTop: Color(0xFFB3E5FC),
          skyBot: Color(0xFFFFE0B2),
          grass: Color(0xFFAED581),
          railColor: Color(0xFFE57373),
          beamColor: Color(0xFFA1887F),
          poleColor: Color(0xFF8D6E63),
        );
      case 2:
      case 3:
        return const _StagePalette(
          skyTop: Color(0xFFB2EBF2),
          skyBot: Color(0xFFFFCCBC),
          grass: Color(0xFF9CCC65),
          railColor: Color(0xFFFFB74D),
          beamColor: Color(0xFF8D6E63),
          poleColor: Color(0xFF6D4C41),
        );
      case 4:
      case 5:
        return const _StagePalette(
          skyTop: Color(0xFF81D4FA),
          skyBot: Color(0xFFF8BBD0),
          grass: Color(0xFFAED581),
          railColor: Color(0xFFBA68C8),
          beamColor: Color(0xFF7986CB),
          poleColor: Color(0xFF5C6BC0),
        );
      case 6:
      case 7:
        return const _StagePalette(
          skyTop: Color(0xFF7E57C2),
          skyBot: Color(0xFFEC407A),
          grass: Color(0xFF9575CD),
          railColor: Color(0xFFFFCA28),
          beamColor: Color(0xFFAB47BC),
          poleColor: Color(0xFF7E57C2),
        );
      default:
        return const _StagePalette(
          skyTop: Color(0xFF1A237E),
          skyBot: Color(0xFFFF5252),
          grass: Color(0xFF7B1FA2),
          railColor: Color(0xFF40C4FF),
          beamColor: Color(0xFFFFD740),
          poleColor: Color(0xFFFFD740),
        );
    }
  }
}
