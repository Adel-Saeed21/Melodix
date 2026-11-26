import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_accent.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Satoshi';

  static ElevatedButtonThemeData _elevatedButtonTheme(
    Color accent,
    Color onAccent,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: onAccent,
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
  static ThemeData light([AppAccent accent = AppAccent.green]) =>
      forColor(accent.color, Brightness.light, onAccent: accent.onColor);

  /// The dark theme in [accent] (the app's green by default).
  static ThemeData dark([AppAccent accent = AppAccent.green]) =>
      forColor(accent.color, Brightness.dark, onAccent: accent.onColor);

  /// A theme in any [accent] (e.g. one taken from the song's cover); text
  /// on it is white unless that can't be read ([AccentColors.onColorFor]).
  static ThemeData forColor(
    Color accent,
    Brightness brightness, {
    Color? onAccent,
  }) => _build(
    accent,
    onAccent ?? AccentColors.onColorFor(accent),
    brightness: brightness,
    background: brightness == Brightness.dark
        ? AppColors.darkBackground
        : AppColors.lightBackground,
  );

  static ThemeData _build(
    Color accent,
    Color onAccent, {
    required Brightness brightness,
    required Color background,
  }) => ThemeData(
    primaryColor: accent,
    scaffoldBackgroundColor: background,
    brightness: brightness,
    fontFamily: _fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      // The accent itself (not a tone derived from it), and a colour that
      // reads on it.
      primary: accent,
      onPrimary: onAccent,
    ),
    elevatedButtonTheme: _elevatedButtonTheme(accent, onAccent),
  );

  /// The default (green) themes.
  static final ThemeData lightTheme = light();
  static final ThemeData darkTheme = dark();
}
