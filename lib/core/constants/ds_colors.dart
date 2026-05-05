import 'package:flutter/material.dart';

class DS {
  // ── Backgrounds ───────────────────────────────────────────────
  static const Color bg           = Color(0xFFFAFAFA); // Ultra-light Gray
  static const Color bgCard       = Color(0xFFFFFFFF); // Pure White
  static const Color shadow       = Color(0x0A000000); // 4% Opacity Black
  static const Color bgElevated   = Color(0xFFFFFFFF); 
  static const Color bgField      = Color(0xFFF3F4F6); // Subtle Gray for inputs
  static const Color bgModal      = Color(0xFFFFFFFF); 

  // ── Brand Colors ──────────────────────────────────────────────
  static const Color primary      = Color(0xFF1F3D3B); // Deep Slate Teal (main accent)
  static const Color secondary    = Color(0xFFF5F7F6); // Soft gray/teal background container
  
  // Aliases for compatibility
  static const Color purple       = primary;           
  static const Color purpleLight  = Color(0xFFF0F3F2);
  static const Color purpleDeep   = Color(0xFF2E4D4B);
  static Color get purpleGlow     => primary.withValues(alpha: 0.1); 
  
  static const Color primaryLight = purpleLight;
  static const Color primaryDeep  = purpleDeep;
  
  static const Color accent       = Color(0xFFFFC043); // Gold / Mustard Yellow
  static const Color gold         = accent;            
  static const Color goldLight    = Color(0xFFFDF0D5);
  static const Color goldDark     = Color(0xFFD4A84D);
  static const Color goldSurface  = Color(0xFFFFFBEB); 
  static const Color borderGold   = Color(0xFFFFD166); 

  // ── Text Palette ──────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF111827); // Dark Gray/Black
  static const Color textSecondary = Color(0xFF6B7280); // Mid Gray
  static const Color textMuted     = Color(0xFF9CA3AF); // Light Gray
  static const Color textHint      = Color(0xFFD1D5DB); // Light Gray

  // ── Status Colors ─────────────────────────────────────────────
  static const Color success       = Color(0xFF22C55E); 
  static const Color successSurface = Color(0xFFF0FDF4);
  static const Color error         = Color(0xFFEF4444);
  static const Color errorSurface   = Color(0xFFFEF2F2);
  static const Color warning       = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color info          = Color(0xFF3B82F6);
  static const Color infoSurface    = Color(0xFFEFF6FF);

  // ── Borders & Dividers ────────────────────────────────────────
  static const Color border        = Color(0xFFE5E7EB); 
  static const Color borderFocus   = primary;
  static const Color divider       = Color(0xFFF3F4F6);

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1F3D3B), Color(0xFF0F1D1C)], 
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = primaryGradient; 

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFFAFAFA), Color(0xFFFFFFFF)], 
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient orbGradient = LinearGradient(
    colors: [Color(0xFFF5F7F6), Color(0xFFE8ECEB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows ───────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.04),
      blurRadius: 10,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get primaryShadow => cardShadow;

  static List<BoxShadow> get purpleShadow => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.08),
      blurRadius: 15,
      spreadRadius: 2,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get goldShadow => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Radii ─────────────────────────────────────────────────────
  static const double radiusCard   = 24.0;
  static const double radiusButton = 18.0;
  static const double radiusField  = 16.0;

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
    color: primary,
  );

  // ── Social Colors ─────────────────────────────────────────────
  static const Color facebook = Color(0xFF1877F2);
  static const Color google   = Color(0xFFDB4437);
  static const Color apple    = Color(0xFF1A1A1A);
}