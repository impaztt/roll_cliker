import 'package:flutter/material.dart';

import '../providers/game_provider.dart';

class FloatingNumberLayer extends StatefulWidget {
  final List<FloatingText> items;
  final Size size;
  const FloatingNumberLayer({
    super.key,
    required this.items,
    required this.size,
  });

  @override
  State<FloatingNumberLayer> createState() => _FloatingNumberLayerState();
}

class _FloatingNumberLayerState extends State<FloatingNumberLayer> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return IgnorePointer(
      child: Stack(
        children: [
          for (final f in widget.items)
            _buildFloat(f, now, widget.size),
        ],
      ),
    );
  }

  Widget _buildFloat(FloatingText f, DateTime now, Size size) {
    final age = now.difference(f.createdAt).inMilliseconds / 1100;
    final t = age.clamp(0.0, 1.0);
    final dx = f.origin.dx * size.width;
    final dy = f.origin.dy * size.height - 50 * t;
    final opacity = (1 - t).clamp(0.0, 1.0);
    final scale = 1 + (f.critical ? 0.4 : 0.1) * (1 - t);
    return Positioned(
      left: dx - 30,
      top: dy - 12,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: f.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: f.color, width: 1.5),
            ),
            child: Text(
              f.text,
              style: TextStyle(
                color: f.color,
                fontWeight: FontWeight.w800,
                fontSize: f.critical ? 18 : 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
