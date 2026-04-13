// lib/core/theme/app_theme.dart
// SINGLE SOURCE OF TRUTH for all visual tokens.
// To retheme the entire app: edit AppColors below.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();
  static const Color gold        = Color(0xFFD4A853);
  static const Color goldLight   = Color(0xFFF0C87A);
  static const Color goldDim     = Color(0x26D4A853);
  static const Color violet      = Color(0xFF8B6FE8);
  static const Color violetLight = Color(0xFFA98EF5);
  static const Color violetDim   = Color(0x268B6FE8);
  static const Color teal        = Color(0xFF2EC4B6);
  static const Color tealDim     = Color(0x202EC4B6);
  static const Color rose        = Color(0xFFE85D8B);
  static const Color roseDim     = Color(0x20E85D8B);
  static const Color inkDeep     = Color(0xFF060610);
  static const Color ink         = Color(0xFF0A0A0F);
  static const Color ink2        = Color(0xFF12121A);
  static const Color ink3        = Color(0xFF1A1A26);
  static const Color surface     = Color(0xFF1F1F2E);
  static const Color surface2    = Color(0xFF252535);
  static const Color surface3    = Color(0xFF2C2C3E);
  static const Color textPrimary   = Color(0xE8FFFFFF);
  static const Color textSecondary = Color(0x8CFFFFFF);
  static const Color textHint      = Color(0x4DFFFFFF);
  static const Color borderSubtle  = Color(0x12FFFFFF);
  static const Color borderDefault = Color(0x1FFFFFFF);
  static const Color borderStrong  = Color(0x33FFFFFF);
  static const Color success = Color(0xFF2EC4B6);
  static const Color warning = Color(0xFFD4A853);
  static const Color error   = Color(0xFFE85D8B);
  static const Color info    = Color(0xFF8B6FE8);
  // Planet colours
  static const Color planetSun     = Color(0xFFD4A853);
  static const Color planetMoon    = Color(0xFFA98EF5);
  static const Color planetMars    = Color(0xFFEF8A6F);
  static const Color planetMercury = Color(0xFF7CC8A0);
  static const Color planetVenus   = Color(0xFFFFAAC4);
  static const Color planetJupiter = Color(0xFFD4A853);
  static const Color planetSaturn  = Color(0xFF9DAECC);
  static const Color planetRahu    = Color(0xFFC8A4E0);
  static const Color planetKetu    = Color(0xFFC8A4E0);

  static Color planetColor(String name) {
    switch (name.toLowerCase()) {
      case 'sun': return planetSun;
      case 'moon': return planetMoon;
      case 'mars': return planetMars;
      case 'mercury': return planetMercury;
      case 'venus': return planetVenus;
      case 'jupiter': return planetJupiter;
      case 'saturn': return planetSaturn;
      default: return planetRahu;
    }
  }
}

class AppSpacing {
  AppSpacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double x3l = 32;
  static const double x4l = 40;
}

class AppRadius {
  AppRadius._();
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 10;
  static const double lg   = 14;
  static const double xl   = 20;
  static const double full = 999;
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLg = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 32, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.2,
  );
  static const TextStyle displayMd = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 24, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.25,
  );
  static const TextStyle displaySm = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 20, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary, height: 1.3,
  );
  static const TextStyle displayXs = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 16, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary, height: 1.35,
  );

  static TextStyle bodyLg = GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.6,
  );
  static TextStyle bodyMd = GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.55,
  );
  static TextStyle bodySm = GoogleFonts.outfit(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );
  static TextStyle bodyXs = GoogleFonts.outfit(
    fontSize: 10, fontWeight: FontWeight.w400,
    color: AppColors.textHint, height: 1.4,
  );

  static TextStyle labelLg = GoogleFonts.outfit(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: 0.02,
  );
  static TextStyle labelMd = GoogleFonts.outfit(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: 0.02,
  );
  static TextStyle labelSm = GoogleFonts.outfit(
    fontSize: 10, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary, letterSpacing: 0.08,
  );

  static TextStyle monoLg = GoogleFonts.spaceMono(
    fontSize: 14, color: AppColors.textPrimary,
  );
  static TextStyle monoMd = GoogleFonts.spaceMono(
    fontSize: 12, color: AppColors.textSecondary,
  );
  static TextStyle monoSm = GoogleFonts.spaceMono(
    fontSize: 9, color: AppColors.textHint, letterSpacing: 0.12,
  );
  static TextStyle sectionTag = GoogleFonts.spaceMono(
    fontSize: 9, fontWeight: FontWeight.w700,
    color: AppColors.gold, letterSpacing: 0.15,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.ink,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.violet,
        tertiary: AppColors.teal,
        error: AppColors.rose,
        surface: AppColors.surface,
        onPrimary: AppColors.ink,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        outline: AppColors.borderDefault,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink2,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textSecondary),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.ink2,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.ink,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderDefault),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        hintStyle: const TextStyle(color: AppColors.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.rose),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle, thickness: 1, space: 0,
      ),
    );
  }
}
