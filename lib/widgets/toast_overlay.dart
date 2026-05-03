import 'package:flutter/material.dart';

import '../providers/game_provider.dart';

class ToastOverlay extends StatelessWidget {
  final List<Toast> toasts;
  const ToastOverlay({super.key, required this.toasts});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in toasts.take(4)) _build(t, now),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build(Toast t, DateTime now) {
    final age = now.difference(t.createdAt).inMilliseconds / 2400.0;
    final fade = (1 - age).clamp(0.0, 1.0);
    return Opacity(
      opacity: fade,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: t.color.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(t.icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                t.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
