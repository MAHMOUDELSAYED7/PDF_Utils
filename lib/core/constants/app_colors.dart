import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const double radius = 16.0;
  static BorderRadius get borderRadius => BorderRadius.circular(radius);

  static const Color gradientStart = Color(0xFF1E3A5F);
  static const Color gradientEnd = Color(0xFF0A1628);

  static const Color primary = Color(0xFF1E3A5F);
  static const Color primaryDark = Color(0xFF0A1628);
  static const Color primaryLight = Color(0xFF3D5A80);
  static const Color accent = Color(0xFF2E4A6F);

  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF616161);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  static BoxDecoration get gradientBackground =>
      BoxDecoration(gradient: primaryGradient, borderRadius: borderRadius);
}
