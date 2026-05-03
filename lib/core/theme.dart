import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFFF8A65);
  static const secondary = Color(0xFF80CBC4);
  static const accent = Color(0xFFFFD54F);
  static const background = Color(0xFFFFF8E1);
  static const premium = Color(0xFFFFCA28);
  static const danger = Color(0xFFEF9A9A);

  static const card = Color(0xFFFFFFFF);
  static const cardSoft = Color(0xFFFFF3E0);
  static const text = Color(0xFF4E342E);
  static const textSoft = Color(0xFF8D6E63);

  static const railWood = Color(0xFFA1887F);
  static const grass = Color(0xFFAED581);
  static const sky = Color(0xFFB3E5FC);
  static const sunset = Color(0xFFFFCCBC);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.background,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      bodyMedium: TextStyle(color: AppColors.text),
      bodySmall: TextStyle(color: AppColors.textSoft),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}
