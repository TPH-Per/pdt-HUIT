import 'package:flutter/material.dart';

/// ============================================================
///  HUIT Brand Color Palette
///  Source: HUIT logo + academic department design guidelines
/// ============================================================
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────
  /// Xanh dương chủ đạo HUIT – header, sidebar, primary buttons
  static const Color primary = Color(0xFF003865);
  static const Color primaryLight = Color(0xFF0B4271);
  static const Color primarySurface = Color(0xFFE8F0F9);

  /// Đỏ HUIT – accent, warnings, cancel buttons
  static const Color accent = Color(0xFFD31826);
  static const Color accentLight = Color(0xFFE11F26);
  static const Color accentSurface = Color(0xFFFDECED);

  // ── Background & Surface ─────────────────────────────────
  /// Nền tổng thể – xám pha xanh nhạt
  static const Color background = Color(0xFFF4F6F9);
  /// Nền card / form
  static const Color surface = Color(0xFFFFFFFF);
  /// Đường viền / divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFDEE2E6);

  // ── Typography ────────────────────────────────────────────
  static const Color textHeading = Color(0xFF1A1A1A);
  static const Color textBody = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textDisabled = Color(0xFFADB5BD);
  static const Color textWhite = Color(0xFFFFFFFF);

  // ── Status ────────────────────────────────────────────────
  static const Color success = Color(0xFF28A745);
  static const Color successLight = Color(0xFFEAF6EC);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color danger = Color(0xFFD31826);
  static const Color dangerLight = Color(0xFFFDECED);
  static const Color info = Color(0xFF0B4271);
  static const Color infoLight = Color(0xFFE8F0F9);

  // ── Gradient ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF003865), Color(0xFF0B4271)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF003865), Color(0xFF005BAA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
