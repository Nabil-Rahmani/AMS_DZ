import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/ds_colors.dart';

class DSTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: DS.bg,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      colorScheme: const ColorScheme.light(
        primary: DS.purple,
        secondary: DS.gold,
        surface: DS.bgCard,
        error: DS.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DS.textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: DS.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: DS.textPrimary, letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: DS.textPrimary, size: 22),
      ),

      cardTheme: CardThemeData(
        color: DS.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: DS.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DS.purple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DS.purple,
          side: const BorderSide(color: DS.purple, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DS.purple,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DS.bgField,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DS.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DS.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DS.purple, width: 1.5),
        ),
        hintStyle: const TextStyle(color: DS.textHint, fontSize: 14),
        labelStyle: const TextStyle(color: DS.textMuted, fontSize: 14),
        // ✅ إصلاح لون النص في كل حقول التطبيق
        suffixIconColor: DS.textMuted,
        prefixIconColor: DS.textMuted,
      ),

      // ✅ إصلاح الشريط السفلي — light theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DS.purple, // أخضر زيتوني
        elevation: 0,
        height: 72,
        indicatorColor: Colors.white.withValues(alpha: 0.15),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? Colors.white : Colors.white.withValues(alpha: 0.55),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(
            color: sel ? Colors.white : Colors.white.withValues(alpha: 0.55),
            size: 22,
          );
        }),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: DS.purple,
        unselectedLabelColor: DS.textMuted,
        indicatorColor: DS.purple,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: DS.divider,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: DS.bgModal,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: DS.bgModal,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: DS.border),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: DS.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: DS.border),
        ),
        contentTextStyle: const TextStyle(
          color: DS.textPrimary, fontSize: 13, fontWeight: FontWeight.w500,
        ),
      ),

      dividerTheme: const DividerThemeData(color: DS.divider, thickness: 1, space: 1),
    );
  }

  // ✅ dark theme — مكتمل مع إصلاح الشريط السفلي والحقول
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light, // ✅ light حتى تظهر النصوص صح على الخلفية الفاتحة
      scaffoldBackgroundColor: DS.bg,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      colorScheme: const ColorScheme.light(
        primary: DS.purple,
        secondary: DS.gold,
        surface: DS.bgCard,
        error: DS.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DS.textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: Colors.white, letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 22),
      ),

      cardTheme: CardThemeData(
        color: DS.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: DS.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DS.purple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DS.purple,
          side: const BorderSide(color: DS.purple, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DS.purple,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // ✅ إصلاح رئيسي: حقول الإدخال تظهر النص دائماً
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DS.bgField,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DS.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DS.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DS.purple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DS.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DS.error, width: 1.5),
        ),
        hintStyle: const TextStyle(color: DS.textHint, fontSize: 14),
        labelStyle: const TextStyle(color: DS.textMuted, fontSize: 14),
        // ✅ لون النص داخل الحقول
        suffixIconColor: DS.textMuted,
        prefixIconColor: DS.textMuted,
      ),

      // ✅ إصلاح الشريط السفلي — أخضر زيتوني
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DS.purple, // Color(0xFF0D9488)
        elevation: 0,
        height: 72,
        indicatorColor: Colors.white.withValues(alpha: 0.15),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? Colors.white : Colors.white.withValues(alpha: 0.55),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(
            color: sel ? Colors.white : Colors.white.withValues(alpha: 0.55),
            size: 22,
          );
        }),
      ),

      // ✅ إصلاح BottomNavigationBar القديم (إذا استعملته)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: DS.purple, // أخضر زيتوني
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withValues(alpha: 0.55),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500,
        ),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: DS.purple,
        unselectedLabelColor: DS.textMuted,
        indicatorColor: DS.purple,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: DS.divider,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: DS.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: DS.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: DS.border),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: DS.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: DS.border),
        ),
        contentTextStyle: const TextStyle(
          color: DS.textPrimary, fontSize: 13, fontWeight: FontWeight.w500,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: DS.divider, thickness: 1, space: 1,
      ),
    );
  }
}