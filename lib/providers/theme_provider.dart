import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_provider.dart';

final appThemeProvider = Provider<ThemeData>((ref) {
  final gameState = ref.watch(gameProvider);
  final eraIndex = gameState.currentEraIndex;

  switch (eraIndex) {
    case 1:
      return _thiefTheme;
    case 2:
      return _mageTheme;
    case 0:
    default:
      return _warriorTheme;
  }
});

// A helper that returns a blocky 8-bit text theme: VT323 for headings/titles, Pixelify Sans for body/labels.
TextTheme _buildRetroTextTheme() {
  final baseTheme = ThemeData.dark().textTheme;
  final bodyTextTheme = GoogleFonts.pixelifySansTextTheme(baseTheme);
  final headingTextTheme = GoogleFonts.vt323TextTheme(baseTheme);

  return bodyTextTheme.copyWith(
    displayLarge: headingTextTheme.displayLarge?.copyWith(fontSize: 40, fontWeight: FontWeight.bold),
    displayMedium: headingTextTheme.displayMedium?.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
    displaySmall: headingTextTheme.displaySmall?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
    headlineLarge: headingTextTheme.headlineLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: headingTextTheme.headlineMedium?.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
    headlineSmall: headingTextTheme.headlineSmall?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
    titleLarge: headingTextTheme.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
    titleMedium: headingTextTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
    titleSmall: headingTextTheme.titleSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
    labelLarge: bodyTextTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
    labelMedium: bodyTextTheme.labelMedium?.copyWith(fontSize: 12),
    labelSmall: bodyTextTheme.labelSmall?.copyWith(fontSize: 10),
  );
}

// Global modifications to button/input styles to make them flat and retro
ThemeData _customizeTheme(ThemeData base, Color primary, Color secondary, Color surface) {
  final textTheme = _buildRetroTextTheme();
  
  return base.copyWith(
    textTheme: textTheme,
    primaryColor: primary,
    scaffoldBackgroundColor: base.scaffoldBackgroundColor,
    colorScheme: base.colorScheme.copyWith(
      primary: primary,
      secondary: secondary,
      surface: surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: secondary),
      titleTextStyle: GoogleFonts.vt323(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: secondary,
      ),
    ),
    // Blocky buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.black, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.vt323(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondary,
        side: BorderSide(color: secondary, width: 2),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.vt323(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondary,
        textStyle: GoogleFonts.vt323(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    // Cards
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: Colors.black, width: 2),
      ),
    ),
    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: Colors.black, width: 3),
      ),
      titleTextStyle: GoogleFonts.vt323(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: secondary,
      ),
      contentTextStyle: GoogleFonts.pixelifySans(
        fontSize: 14,
        color: Colors.white70,
      ),
    ),
    // Inputs (TextField)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      labelStyle: GoogleFonts.pixelifySans(color: Colors.grey[400]),
      floatingLabelStyle: GoogleFonts.pixelifySans(color: secondary),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: secondary, width: 2),
      ),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
    ),
  );
}

// Era 0: Warrior Theme (Stone/Dark Grey, Blood Red, Gold)
final _warriorTheme = _customizeTheme(
  ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1C1C1C),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8B0000), // Blood Red
      secondary: Color(0xFFFFD700), // Gold
      surface: Color(0xFF2C2C2C),
    ),
  ),
  const Color(0xFF8B0000), // Blood Red
  const Color(0xFFFFD700), // Gold
  const Color(0xFF2C2C2C),
);

// Era 1: Thief Theme (Dark Navy, Deep Purple, Cyan/Neon)
final _thiefTheme = _customizeTheme(
  ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0E14),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6200EA), // Deep Purple
      secondary: Color(0xFF00E5FF), // Cyan/Neon
      surface: Color(0xFF121212),
    ),
  ),
  const Color(0xFF6200EA),
  const Color(0xFF00E5FF),
  const Color(0xFF121212),
);

// Era 2: Mage Theme (Starfield Black, Cyan, Pink/Iridescent)
final _mageTheme = _customizeTheme(
  ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF000000),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00BCD4), // Cyan
      secondary: Color(0xFFFF4081), // Pink/Iridescent
      surface: Color(0xFF1A1A1A),
    ),
  ),
  const Color(0xFF00BCD4),
  const Color(0xFFFF4081),
  const Color(0xFF1A1A1A),
);
