import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_accent.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/config/theme/app_theme.dart';

/// WCAG contrast ratio between two colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test("green is the app's own colour and the default", () {
    expect(AppAccent.green.color, AppColors.primaryColor);
    expect(AppTheme.darkTheme.primaryColor, AppColors.primaryColor);
  });

  test('the themes take the chosen accent (light and dark)', () {
    for (final accent in AppAccent.values) {
      for (final theme in [AppTheme.light(accent), AppTheme.dark(accent)]) {
        expect(theme.primaryColor, accent.color, reason: accent.name);
        expect(theme.colorScheme.primary, accent.color, reason: accent.name);
      }
    }
  });

  test("the default keeps the app's look: white on its green", () {
    expect(AppAccent.green.onColor, Colors.white);
    expect(AppTheme.darkTheme.colorScheme.onPrimary, Colors.white);
  });

  test('text and icons on every accent are readable', () {
    for (final accent in AppAccent.values) {
      expect(
        contrast(accent.color, accent.onColor),
        greaterThanOrEqualTo(2.0),
        reason: '${accent.name}: ${accent.onColor} on ${accent.color}',
      );
      expect(AppTheme.dark(accent).colorScheme.onPrimary, accent.onColor);
    }
    // Yellow is light: dark text on it, not white.
    expect(AppAccent.yellow.onColor, isNot(Colors.white));
  });

  test('the Favourites gradient follows the accent, darker at the end', () {
    final gradient = AccentColors.favouritesGradient(AppAccent.purple.color);
    expect(gradient.first, AppAccent.purple.color);
    expect(
      gradient.last.computeLuminance(),
      lessThan(gradient.first.computeLuminance()),
    );
  });
}
