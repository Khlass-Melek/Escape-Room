
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryBlack = Color(0xFF0D0D0D); // Backgrounds
  static const Color secondaryBlack = Color(0xFF1A1A1A); // Cards, Surfaces
  static const Color primaryRed = Color(0xFFDC143C); // Crimson - Accents, Active
  static const Color secondaryRed = Color(0xFF8B0000); // Dark Red - Hover, Borders
  static const Color white = Color(0xFFFFFFFF); // Text, Icons
  static const Color grayBorder = Color(0xFF2D2D2D);
  static const Color grayDisabled = Color(0xFF4A4A4A);
  static const Color grayText = Color(0xFFB8B8B8);

  // Status Colors
  static const Color successGreen = Color(0xFF28A745);
  static const Color warningOrange = Color(0xFFFFA500);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBlack,
      primaryColor: primaryRed,
      canvasColor: primaryBlack,
      cardColor: secondaryBlack,
      dividerColor: grayBorder,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: secondaryRed,
        surface: secondaryBlack,
        error: primaryRed,
        onPrimary: white,
        onSecondary: white,
        onSurface: white,
        onError: white,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        displayMedium: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: white,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: white,
        ),
        labelLarge: GoogleFonts.robotoMono(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: grayText,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: secondaryBlack,
        elevation: 4,
        shadowColor: const Color(0x80000000), // Darker shadow
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF333333), width: 1), // Lighter border
          borderRadius: BorderRadius.circular(20), // More rounded
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF222222),
        hintStyle: const TextStyle(color: grayText),
        labelStyle: const TextStyle(color: white),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primaryRed, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: white,
          elevation: 4,
          shadowColor: primaryRed.withValues(alpha: 0.4),
          textStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: white,
        size: 24,
      ),
    );
  }
}