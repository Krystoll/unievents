import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class ReliabilityBadge extends StatelessWidget {
  const ReliabilityBadge({super.key, required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final percent = score.round();
    final Color color;
    final IconData icon;
    if (score >= 80) {
      color = AppColors.success;
      icon = Icons.verified_rounded;
    } else if (score >= 50) {
      color = AppColors.warning;
      icon = Icons.info_outline_rounded;
    } else {
      color = AppColors.error;
      icon = Icons.warning_amber_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            'Надёжность: $percent%',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}
