import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_accent.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Satoshi';

  static ElevatedButtonThemeData _elevatedButtonTheme(AppAccent accent) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent.color,
        foregroundColor: accent.onColor,
        textStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: AppTextSizes.lg,
          fontWeight: FontWeightHelper.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.r),
        ),
      ),
    );
  }

  /// The light theme in [accent] (the app's green by default).
  static ThemeData light([AppAccent accent = AppAccent.green]) => _build(
    accent,
    brightness: Brightness.light,
    background: AppColors.lightBackground,
  );

  /// The dark theme in [accent] (the app's green by default).
  static ThemeData dark([AppAccent accent = AppAccent.green]) => _build(
    accent,
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
  );

  static ThemeData _build(
    AppAccent accent, {
    required Brightness brightness,
    required Color background,
  }) => ThemeData(
    primaryColor: accent.color,
    scaffoldBackgroundColor: background,
    brightness: brightness,
    fontFamily: _fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent.color,
      brightness: brightness,
      // The accent itself (not a tone derived from it), and a colour that
      // reads on it.
      primary: accent.color,
      onPrimary: accent.onColor,
    ),
    elevatedButtonTheme: _elevatedButtonTheme(accent),
  );

  /// The default (green) themes.
  static final ThemeData lightTheme = light();
  static final ThemeData darkTheme = dark();
}
