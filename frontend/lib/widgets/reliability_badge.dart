import 'package:flutter/material.dart';

class ReliabilityBadge extends StatelessWidget {
  const ReliabilityBadge({super.key, required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final percent = score.round();
    final Color color;
    final String icon;
    if (score >= 80) {
      color = Colors.green;
      icon = '👍';
    } else if (score >= 50) {
      color = Colors.amber;
      icon = '⚠️';
    } else {
      color = Colors.red;
      icon = '⚠️';
    }
    return Chip(
      label: Text('$icon Надёжность: $percent%'),
      side: BorderSide(color: color),
      backgroundColor: color.withValues(alpha: 0.12),
    );
  }
}
