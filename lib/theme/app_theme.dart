import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color primaryAccent = Color(0xFF0EA5E9);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // App Custom Blue Palette (Brand Consistency)
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  // Light Neutral/Grayscale
  static const Color surfaceBlack = Color(0xFF0F172A);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  static const Color surface0 = Color(0xFFFFFFFF);
  static const Color surface1 = Color(0xFFF8FAFC);
  static const Color surface2 = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // Dark Neutral - Using Blue Palette for Consistency
  static const Color darkBackground = Color(0xFF192338);   // oxfordBlue
  static const Color darkSurface = Color(0xFF1E2E4F);       // spaceCadet
  static const Color darkSurface2 = Color(0xFF31487A);      // yinMnBlue
  static const Color darkBorder = Color(0xFF8FB3E2);        // jordyBlue
  
  // Convenience alias for legacy code
  static const Color spaceCadetAlias = Color(0xFF1E2E4F);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

class AppRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 20.0;
  static const double pill = 999.0;
}

class AppShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A000000), // 10% black
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0F000000), // 15% black
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x14000000), // 20% black
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x19000000), // 25% black
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}