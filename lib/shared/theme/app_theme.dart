import 'package:flutter/material.dart';

class AppTheme {
  static const double windowWidth = 410;
  static const double windowHeight = 580;
  static const double tabBarHeight = 48;
  static const EdgeInsets paddingPagina = EdgeInsets.all(16);

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A84FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: '.AppleSystemUIFont',
      );

  static ThemeData get dark => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A84FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: '.AppleSystemUIFont',
      );
}
