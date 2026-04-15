import 'package:flutter/material.dart';

/// AMS-DZ Design System — Dark Auction Theme
/// Primary: Deep Black + Purple Gradient + Gold Accent
class DS {
  // ── Backgrounds ───────────────────────────────────────────────
  static const Color bg          = Color(0xFFFFFFFF); // pure white
  static const Color bgCard      = Color(0xFFF8F9FB); // very light gray surface
  static const Color bgElevated  = Color(0xFFFFFFFF); // elevated surface
  static const Color bgField     = Color(0xFFF3F4F6); // input field light gray
  static const Color bgModal     = Color(0xFFFFFFFF); // bottom sheet

  // ── Purple family ─────────────────────────────────────────────
  static const Color purple      = Color(0xFF7C3AED); // slightly deeper purple for light mode contrast
  static const Color purpleDark  = Color(0xFF5B21B6); 
  static const Color purpleDeep  = Color(0xFFF5F3FF); // very light purple tint for bgs
  static const Color purpleGlow  = Color(0x157C3AED); // subtle glow for light mode

  // ── Gold accent (auction brand) ───────────────────────────────
  static const Color gold        = Color(0xFFB45309); // adjusted for readability on light bg
  static const Color goldLight   = Color(0xFFD97706);
  static const Color goldDark    = Color(0xFF92400E);
  static const Color goldSurface = Color(0xFFFFFBEB); // light gold tint
  static const Color goldGlow    = Color(0x10B45309);

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF111827); // almost black
  static const Color textSecondary = Color(0xFF4B5563); // gray-600
  static const Color textMuted     = Color(0xFF9CA3AF); // gray-400
  static const Color textHint      = Color(0xFFD1D5DB); // gray-300

  // ── Status ────────────────────────────────────────────────────
  static const Color success       = Color(0xFF10B981);
  static const Color successSurface= Color(0xFFECFDF5);
  static const Color error         = Color(0xFFEF4444);
  static const Color errorSurface  = Color(0xFFFEF2F2);
  static const Color warning       = Color(0xFFF59E0B);
  static const Color warningSurface= Color(0xFFFFFBEB);
  static const Color info          = Color(0xFF3B82F6);
  static const Color infoSurface   = Color(0xFFEFF6FF);

  // ── Borders ───────────────────────────────────────────────────
  static const Color border        = Color(0xFFE5E7EB); // gray-200
  static const Color borderFocus   = Color(0xFF7C3AED);
  static const Color borderGold    = Color(0xFFFDE68A);
  static const Color divider       = Color(0xFFF3F4F6);

  // ── Auction Status colors ─────────────────────────────────────
  static const Color statusDraft     = Color(0xFF9CA3AF);
  static const Color statusSubmitted = Color(0xFF3B82F6);
  static const Color statusApproved  = Color(0xFF7C3AED);
  static const Color statusActive    = Color(0xFF10B981);
  static const Color statusEnded     = Color(0xFF6B7280);
  static const Color statusRejected  = Color(0xFFEF4444);

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFFF9FAFB), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient orbGradient = RadialGradient(
    colors: [Color(0x208B5CF6), Color(0x108B5CF6), Color(0x00FFFFFF)],
    stops: [0.0, 0.5, 1.0],
    radius: 0.8,
  );

  // ── Shadows ───────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.05),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get purpleShadow => [
    BoxShadow(
      color: purple.withValues(alpha: 0.2),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get goldShadow => [
    BoxShadow(
      color: gold.withValues(alpha: 0.15),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];

  // ── Typography helpers ────────────────────────────────────────
  static TextStyle get displayLarge => const TextStyle(
    fontSize: 32, fontWeight: FontWeight.w800,
    color: textPrimary, letterSpacing: -1.0, height: 1.2,
  );

  static TextStyle get titleXL => const TextStyle(
    fontSize: 26, fontWeight: FontWeight.w800,
    color: textPrimary, letterSpacing: -0.5, height: 1.2,
  );

  static TextStyle get titleL => const TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: textPrimary, letterSpacing: -0.3,
  );

  static TextStyle get titleM => const TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get titleS => const TextStyle(
    fontSize: 15, fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get body => const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: textSecondary, height: 1.5,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle get label => const TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: textMuted, letterSpacing: 0.5,
  );

  static TextStyle get gold_text => const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w700,
    color: gold,
  );

  static TextStyle get purple_text => const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: purple,
  );
}
