import 'package:flutter/material.dart';

import '../core/number_format.dart';
import '../core/theme.dart';

class OfflineRewardDialog extends StatelessWidget {
  final double amount;
  final Duration duration;
  final VoidCallback onClaim;

  const OfflineRewardDialog({
    super.key,
    required this.amount,
    required this.duration,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: const Text('대표님이 없는 동안'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '롤러코스터가 ${NumberFormatter.formatTime(duration)} 동안 운행했어요!',
            style: const TextStyle(color: AppColors.textSoft),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.attach_money,
                    color: Color(0xFFFFA726), size: 36),
                const SizedBox(height: 8),
                Text(
                  '+${NumberFormatter.format(amount)} 코인',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: onClaim,
          icon: const Icon(Icons.check),
          label: const Text('받기'),
        ),
      ],
    );
  }
}
