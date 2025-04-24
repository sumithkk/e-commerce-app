import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 16),
        headlineSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      ),
    );
  }
}
