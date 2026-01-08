import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// Era 0: Warrior
final _warriorTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.red,
  scaffoldBackgroundColor: const Color(0xFF1C1C1C), // Stone/Dark Grey
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF8B0000), // Blood Red
    secondary: Color(0xFFFFD700), // Gold
    surface: Color(0xFF2C2C2C),
  ),
  textTheme: ThemeData.dark().textTheme.apply(
    fontFamily: 'Cinzel',
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2C2C2C),
    titleTextStyle: TextStyle(
      fontFamily: 'Cinzel',
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
);

// Era 1: Thief
final _thiefTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.deepPurple,
  scaffoldBackgroundColor: const Color(0xFF0A0E14), // Dark Navy
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF6200EA), // Deep Purple
    secondary: Color(0xFF00E5FF), // Cyan/Neon
    surface: Color(0xFF121212),
  ),
  textTheme: ThemeData.dark().textTheme.apply(
    fontFamily: 'Lato',
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF121212),
    titleTextStyle: TextStyle(
      fontFamily: 'Lato',
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
);

// Era 2: Mage
final _mageTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.cyan,
  scaffoldBackgroundColor: const Color(0xFF000000), // Starfield Black
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF00BCD4), // Cyan
    secondary: Color(0xFFFF4081), // Pink/Iridescent
    surface: Color(0xFF1A1A1A),
  ),
  textTheme: ThemeData.dark().textTheme.apply(
    fontFamily: 'UncialAntiqua',
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A1A1A),
    titleTextStyle: TextStyle(
      fontFamily: 'UncialAntiqua',
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
);
