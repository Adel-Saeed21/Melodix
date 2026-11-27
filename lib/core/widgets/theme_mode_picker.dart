import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/theme_cubit/theme_cubit.dart';
import 'package:melodix/core/widgets/theme_mode_picker/theme_mode_card.dart';

/// The look: dark, light or the phone's, each a little phone drawn in that
/// look. Tapping one applies it to the whole app at once (the screen it's on
/// changes around it). Used by the onboarding and Settings.
class ThemeModePicker extends StatelessWidget {
  const ThemeModePicker({super.key});

  static List<(ThemeMode, IconData, String)> _options(AppLocalizations l10n) =>
      [
        (ThemeMode.dark, Icons.dark_mode_rounded, l10n.themeDark),
        (ThemeMode.light, Icons.light_mode_rounded, l10n.themeLight),
        (ThemeMode.system, Icons.brightness_auto_rounded, l10n.onboardingAuto),
      ];

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;
    final phoneDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (value, icon, label) in _options(context.l10n))
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.r),
            child: ThemeModeCard(
              icon: icon,
              label: label,
              dark: switch (value) {
                ThemeMode.dark => true,
                ThemeMode.light => false,
                ThemeMode.system => phoneDark,
              },
              split: value == ThemeMode.system,
              selected: value == mode,
              onTap: () => context.read<ThemeCubit>().updateTheme(value),
            ),
          ),
      ],
    );
  }
}
