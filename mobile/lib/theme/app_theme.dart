import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta oficial AulaSync extraída de Figma (`AulaSync Tokens` - `wxHaCh9m8ZU4OPMOCPJgLm`).
class AppColors {
  AppColors._();

  // Brand
  static const Color navyDeep = Color(0xFF071A2F);
  static const Color navy = Color(0xFF0B2F4F);
  static const Color teal = Color(0xFF0F766E);
  static const Color tealBright = Color(0xFF14B8A6);
  static const Color tealSoft = Color(0xFF5EEAD4);
  static const Color tealLight = Color(0xFF99F6E4);
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldBright = Color(0xFF34D399);

  // Canvas & Surfaces (Figma #EEF2F7 / #FFFFFF / #F1F5F9)
  static const Color background = Color(0xFFEEF2F7);
  static const Color splashBackground = Color(0xFFF4F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color surfaceSubtle = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);

  // Semantic Status
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);
  static const Color warning = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);
  static const Color info = Color(0xFF1D4ED8);
  static const Color infoBg = Color(0xFFEFF6FF);

  /// Gradiente oficial Figma `GRAD_HERO` (`#071A2F` -> `#0B2F4F` -> `#0F766E`).
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDeep, navy, teal],
    stops: [0.0, 0.41, 0.74],
  );
}

class AppRadii {
  AppRadii._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double pill = 999;
}

class AppShadows {
  AppShadows._();

  /// Figma `SHADOW_CARD`: `0 2px 6px rgba(10,26,51,0.03), 0 8px 24px rgba(10,26,51,0.06)`
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x080A1A33),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0F0A1A33),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Figma `SHADOW_HERO`: `0 14px 28px rgba(11,47,79,0.28)`
  static const List<BoxShadow> hero = [
    BoxShadow(
      color: Color(0x470B2F4F),
      blurRadius: 28,
      offset: Offset(0, 14),
    ),
  ];

  static const List<BoxShadow> cta = [
    BoxShadow(
      color: Color(0x400B2F4F),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
}

class AppTheme {
  AppTheme._();

  static TextStyle get tabularMono => GoogleFonts.robotoMono(
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle displayFont({
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w800,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.sora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.roboto().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        onPrimary: Colors.white,
        secondary: AppColors.teal,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.sora(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.6,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        labelStyle: GoogleFonts.roboto(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.roboto(
          color: AppColors.textMuted,
          fontSize: 13,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
