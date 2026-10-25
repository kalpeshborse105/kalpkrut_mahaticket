import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // MahaTicket Signature Warm Orange / Charcoal Theme (BookMyShow + TicketGhar hybrid)
  static const Color background = Color(0xFF0F172A); // Rich Slate Black
  static const Color surface = Color(0xFF1E293B); // Slate Surface
  static const Color surfaceLight = Color(0xFF334155); // Highlight surface
  static const Color surfaceBorder = Color(0xFF475569); // Subtle Slate border
  static const Color canvasLight = Color(0xFFFFF7ED); // Warm cream accent

  // Brand Orange Accent (MahaTicket Warm Orange)
  static const Color primary = Color(0xFFEA580C); // Warm Orange
  static const Color primaryDark = Color(0xFFC2410C); // Deep Burnt Orange
  static const Color primaryLight = Color(0xFFF97316); // Bright Orange
  static const Color primaryGradientStart = Color(0xFFEA580C);
  static const Color primaryGradientEnd = Color(0xFFF59E0B);

  // Secondary Accents & Highlights
  static const Color accent = Color(0xFFE11D48); // Rose Crimson
  static const Color gold = Color(0xFFF59E0B); // Amber Gold
  static const Color goldLight = Color(0xFFFDE68A);
  static const Color cyan = Color(0xFF06B6D4);

  // Seat Status Colors
  static const Color seatAvailable = Color(0xFF1E293B);
  static const Color seatAvailableBorder = Color(0xFF64748B);
  static const Color seatSelected = Color(0xFFEA580C); // Brand Orange
  static const Color seatHeld = Color(0xFFF59E0B); // Amber warning
  static const Color seatBooked = Color(0xFF0F172A); // Dark muted
  static const Color seatVip = Color(0xFFF59E0B); // Royal Gold

  // Feedback Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color neonGreen = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444); // Crimson Error
  static const Color warning = Color(0xFFF59E0B); // Amber Warning

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
