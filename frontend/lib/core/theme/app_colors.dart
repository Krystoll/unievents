import 'package:flutter/material.dart';

/// Палитра UniEvents.
abstract final class AppColors {
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color accent = Color(0xFF8B5CF6);

  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceContainer = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF6366F1)],
  );

  static const LinearGradient cardAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
  );
}
