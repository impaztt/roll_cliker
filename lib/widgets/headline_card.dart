import 'package:flutter/material.dart';

import '../core/number_format.dart';

/// Compact upgrade card used on the home screen for the three headline
/// upgrades (Ticket / Speed / Cars).
class HeadlineCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int level;
  final double cost;
  final bool affordable;
  final bool isMax;
  final VoidCallback onBuy;

  const HeadlineCard({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.level,
    required this.cost,
    required this.affordable,
    required this.onBuy,
    this.isMax = false,
  });

  @override
  Widget build(BuildContext context) {
    final dim = !affordable && !isMax;
    return GestureDetector(
      onTap: (isMax || !affordable) ? null : onBuy,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF4E342E),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Lv $level',
              style: const TextStyle(
                color: Color(0xFF8D6E63),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isMax
                    ? const Color(0xFF80CBC4)
                    : (dim ? const Color(0xFFE0E0E0) : color),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  isMax ? 'MAX' : NumberFormatter.format(cost),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
