import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 56,
    this.showTitle = true,
    this.light = false,
  });

  final double size;
  final bool showTitle;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final titleColor = light ? Colors.white : AppColors.textPrimary;
    final subtitleColor = light ? Colors.white70 : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppColors.cardAccent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'UniEvents',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Университетские мероприятия',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: subtitleColor),
          ),
        ],
      ],
    );
  }
}
