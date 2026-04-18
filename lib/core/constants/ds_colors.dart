import 'package:flutter/material.dart';

class DS {
  // ── Backgrounds ───────────────────────────────────────────────
  static const Color bg         = Color(0xFFF0FAFA); // teal-tinted white
  static const Color bgCard     = Color(0xFFFFFFFF);
  static const Color bgElevated = Color(0xFFFFFFFF);
  static const Color bgField    = Color(0xFFEEF9F9);
  static const Color bgModal    = Color(0xFFFFFFFF);

  // ── Teal family (replaces purple) ─────────────────────────────
  static const Color purple      = Color(0xFF0D9488); // teal-600
  static const Color purpleDark  = Color(0xFF0F766E); // teal-700
  static const Color purpleDeep  = Color(0xFFECFDF5); // teal tint bg
  static const Color purpleGlow  = Color(0x150D9488);

  // ── Gold accent ───────────────────────────────────────────────
  static const Color gold        = Color(0xFFD97706);
  static const Color goldLight   = Color(0xFFF59E0B);
  static const Color goldDark    = Color(0xFF92400E);
  static const Color goldSurface = Color(0xFFFFFBEB);
  static const Color goldGlow    = Color(0x10D97706);

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted     = Color(0xFF9CA3AF);
  static const Color textHint      = Color(0xFFD1D5DB);

  // ── Status ────────────────────────────────────────────────────
  static const Color success        = Color(0xFF10B981);
  static const Color successSurface = Color(0xFFECFDF5);
  static const Color error          = Color(0xFFEF4444);
  static const Color errorSurface   = Color(0xFFFEF2F2);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color info           = Color(0xFF0D9488);
  static const Color infoSurface    = Color(0xFFECFDF5);

  // ── Borders ───────────────────────────────────────────────────
  static const Color border      = Color(0xFFCCEEEB);
  static const Color borderFocus = Color(0xFF0D9488);
  static const Color borderGold  = Color(0xFFFDE68A);
  static const Color divider     = Color(0xFFE6F7F6);

  // ── Auction Status ────────────────────────────────────────────
  static const Color statusDraft     = Color(0xFF9CA3AF);
  static const Color statusSubmitted = Color(0xFF0D9488);
  static const Color statusApproved  = Color(0xFF0F766E);
  static const Color statusActive    = Color(0xFF10B981);
  static const Color statusEnded     = Color(0xFF6B7280);
  static const Color statusRejected  = Color(0xFFEF4444);

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFFF0FAFA), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient orbGradient = RadialGradient(
    colors: [Color(0x2014B8A6), Color(0x1014B8A6), Color(0x00FFFFFF)],
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

  // ── Typography ────────────────────────────────────────────────
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