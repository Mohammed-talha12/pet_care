import 'package:flutter/material.dart';

class AppTheme {
  // Main colors for the Pet Care brand
  static const Color primaryColor = Color(0xFF6C63FF); // Friendly Purple
  static const Color secondaryColor = Color(0xFF00C853); // Trustworthy Green
  static const Color backgroundColor = Color(0xFFF5F5F5);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}