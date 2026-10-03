import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design System ProxServ - Échelle Typographique (Police Inter / System)
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  static TextTheme textTheme(bool isDark) {
    final primaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return TextTheme(
      // H1 : 28px / 700
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        height: 1.2,
      ),
      // H2 : 22px / 700
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        height: 1.3,
      ),
      // H3 : 18px / 600
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.3,
      ),
      // Title Medium / Subtitle
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      // Body Large : 16px / 400
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: primaryColor,
      ),
      // Body : 14px / 400-500
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primaryColor,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),
      // Label : 14px / 600
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      // Caption : 12px / 500
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
    );
  }

  // Preset pour Important : 16px / 700
  static TextStyle important(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color:
          color ??
          (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }
}
