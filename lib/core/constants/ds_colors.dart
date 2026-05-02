import 'package:flutter/material.dart';

class DS {
  static const Color bg         = Color(0xFFF0FDF4);
  static const Color bgCard     = Color(0xFFFFFFFF);
  static const Color bgElevated = Color(0xFFF0FDF4);
  static const Color bgField    = Color(0xFFECFDF5);
  static const Color bgModal    = Color(0xFFFFFFFF);

  static const Color purple      = Color(0xFF059669);
  static const Color purpleDark  = Color(0xFF047857);
  static const Color purpleDeep  = Color(0xFFECFDF5);
  static const Color purpleGlow  = Color(0x15059669);

  static const Color gold        = Color(0xFFD97706);
  static const Color goldLight   = Color(0xFFF59E0B);
  static const Color goldDark    = Color(0xFF92400E);
  static const Color goldSurface = Color(0xFFFFFBEB);
  static const Color goldGlow    = Color(0x10D97706);

  static const Color textPrimary   = Color(0xFF064E3B);
  static const Color textSecondary = Color(0xFF065F46);
  static const Color textMuted     = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFFD1D5DB);

  static const Color success        = Color(0xFF10B981);
  static const Color successSurface = Color(0xFFECFDF5);
  static const Color error          = Color(0xFFEF4444);
  static const Color errorSurface   = Color(0xFFFEF2F2);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color info           = Color(0xFF059669);
  static const Color infoSurface    = Color(0xFFECFDF5);

  static const Color border      = Color(0xFFD1FAE5);
  static const Color borderFocus = Color(0xFF059669);
  static const Color borderGold  = Color(0xFFFDE68A);
  static const Color divider     = Color(0xFFD1FAE5);

  static const Color statusDraft     = Color(0xFF9CA3AF);
  static const Color statusSubmitted = Color(0xFF059669);
  static const Color statusApproved  = Color(0xFF047857);
  static const Color statusActive    = Color(0xFF10B981);
  static const Color statusEnded     = Color(0xFF6B7280);
  static const Color statusRejected  = Color(0xFFEF4444);

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFFF0FDF4), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient orbGradient = RadialGradient(
    colors: [Color(0x2005B876), Color(0x1005B876), Color(0x00FFFFFF)],
    stops: [0.0, 0.5, 1.0],
    radius: 0.8,
  );

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