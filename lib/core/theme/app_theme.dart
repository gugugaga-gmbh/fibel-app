import 'package:material_ui/material_ui.dart';

class AppColors {
  static const Color paperBackground = Color(0xFFFFFDF7);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color syllableBlue = Color(0xFF1E64D8);
  static const Color syllableRed = Color(0xFFD93025);
  static const Color foxOrange = Color(0xFFF57C00);
  static const Color owlTeal = Color(0xFF00897B);
  static const Color starGold = Color(0xFFFFB300);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color lineHouseRoof = Color(0xFFE57373);
  static const Color lineHouseMain = Color(0xFF64B5F6);
  static const Color lineHouseCellar = Color(0xFF81C784);
}

class AppTheme {
  static ThemeData buildTheme({bool highContrast = false}) {
    final bgColor = highContrast ? Colors.white : AppColors.paperBackground;
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Andika',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.syllableBlue,
        surface: bgColor,
      ),
      scaffoldBackgroundColor: bgColor,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937), size: 28),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: highContrast ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: highContrast
              ? const BorderSide(color: Color(0xFF1F2937), width: 2)
              : BorderSide.none,
        ),
      ),
    );
  }
}
