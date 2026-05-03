import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../providers/game_provider.dart';

class GoldenGuestWidget extends StatefulWidget {
  final GoldenGuest guest;
  final VoidCallback onTap;
  const GoldenGuestWidget({
    super.key,
    required this.guest,
    required this.onTap,
  });

  @override
  State<GoldenGuestWidget> createState() => _GoldenGuestWidgetState();
}

class _GoldenGuestWidgetState extends State<GoldenGuestWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final bob = math.sin(_ctrl.value * math.pi * 2) * 4;
        return Transform.translate(
          offset: Offset(0, bob),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCA28),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '태워줘! ★',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFCA28).withValues(alpha: 0.7),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.emoji_emotions,
                        color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widget.guest.hp / 10.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
