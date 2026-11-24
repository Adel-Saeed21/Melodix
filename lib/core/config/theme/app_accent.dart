import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_colors.dart';

/// The accent colour the user picks in Settings (buttons, highlights, the
/// play button, the Favourites gradient). Green is the app's own.
enum AppAccent {
  green(AppColors.primaryColor, 'Green'),
  blue(Color(0xff3D8BFD), 'Blue'),
  purple(Color(0xff9B5CF6), 'Purple'),
  pink(Color(0xffEC4899), 'Pink'),
  red(Color(0xffEF4444), 'Red'),
  orange(Color(0xffF97316), 'Orange'),
  yellow(Color(0xffF5B700), 'Yellow', onLight: true),
  teal(Color(0xff14B8A6), 'Teal');

  const AppAccent(this.color, this.label, {this.onLight = false});

  final Color color;
  final String label;

  /// So light that white on it can't be read: dark text and icons instead.
  final bool onLight;

  /// Text and icons on the accent: white, as the app always had (on its
  /// green too); dark only on a very light accent (yellow).
  Color get onColor => onLight ? const Color(0xff1A1A1A) : Colors.white;
}

/// Accent-dependent colours, read from the theme (they follow the user's
/// accent; [AppColors] holds the fixed ones).
abstract final class AccentColors {
  /// The Favourites gradient (top-left → bottom-right) for [accent].
  static List<Color> favouritesGradient(Color accent) => [
    accent,
    _deep(accent),
  ];

  static Color _deep(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.55).clamp(0.0, 1.0)).toColor();
  }

  /// The colour for text and icons drawn on [accent].
  static Color on(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;
}
