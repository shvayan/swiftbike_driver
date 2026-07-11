import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand

  static const Color primary = Color(0xFF2196F3);

  static const Color primaryDark = Color(0xff6C4CF1);

  static const Color primaryLight = Color(0xFFE3F2FD);

  // Background

  static const Color background = Color(0xFFF8FAFC);

  static const Color surface = Colors.white;

  // Text

  static const Color textPrimary = Color(0xFF0F172A);

  static const Color textSecondary = Color(0xFF64748B);

  // Border

  static const Color border = Color(0xFFE2E8F0);

  // Status

  static const Color success = Color(0xFF22C55E);

  static const Color warning = Color(0xFFF59E0B);

  static const Color error = Color(0xFFEF4444);

  // Others

  static const Color white = Colors.white;

  static const Color black = Colors.black;

  static final Color primarySoft = Color.lerp(primary, Colors.white, 0.90)!;
  static final Color primarySofter = Color.lerp(primary, Colors.white, 0.95)!;

  static final Color primaryDeep = Color.lerp(primary, Colors.black, 0.25)!;

  static const Color danger = AppColors.error;
  static final Color dangerSoft = Color.lerp(danger, Colors.white, 0.90)!;
}

class _Palette {
  _Palette._();

  static const Color primary = AppColors.primaryDark; // #6C4CF1
  static final Color primaryDeep = Color.lerp(primary, Colors.black, 0.25)!;
  static final Color primarySoft = Color.lerp(primary, Colors.white, 0.90)!;
  static final Color primarySofter = Color.lerp(primary, Colors.white, 0.95)!;

  static const Color danger = AppColors.error;
  static final Color dangerSoft = Color.lerp(danger, Colors.white, 0.90)!;
}
