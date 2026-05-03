import 'package:flutter/material.dart';

import '../models/stock_market.dart';

class CandleChart extends StatelessWidget {
  final List<Candle> candles;
  const CandleChart({super.key, required this.candles});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CandlePainter(candles: candles),
      child: const SizedBox.expand(),
    );
  }
}

class _CandlePainter extends CustomPainter {
  final List<Candle> candles;
  _CandlePainter({required this.candles});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;
    var lo = candles.first.low;
    var hi = candles.first.high;
    for (final c in candles) {
      if (c.low < lo) lo = c.low;
      if (c.high > hi) hi = c.high;
    }
    if (hi <= lo) hi = lo + 1;
    final span = hi - lo;
    final w = size.width / candles.length;
    final bgGrid = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = 0.5;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), bgGrid);
    }

    for (var i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = w * i + w / 2;
      final yHigh = _toY(c.high, lo, span, size.height);
      final yLow = _toY(c.low, lo, span, size.height);
      final yOpen = _toY(c.open, lo, span, size.height);
      final yClose = _toY(c.close, lo, span, size.height);
      final up = c.close >= c.open;
      final color = up ? const Color(0xFFEF5350) : const Color(0xFF42A5F5);
      final wick = Paint()
        ..color = color
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), wick);
      final body = Paint()..color = color;
      final top = up ? yClose : yOpen;
      final bot = up ? yOpen : yClose;
      final bw = (w * 0.6).clamp(2.0, 8.0);
      canvas.drawRect(
        Rect.fromLTWH(x - bw / 2, top, bw, (bot - top).abs().clamp(1, 999)),
        body,
      );
    }
  }

  double _toY(double v, double lo, double span, double h) {
    final t = (v - lo) / span;
    return h - t * h;
  }

  @override
  bool shouldRepaint(covariant _CandlePainter old) =>
      old.candles != candles;
}
