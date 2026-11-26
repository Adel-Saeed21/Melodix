import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/config/theme/theme_cubit/theme_cubit.dart';

/// The look: dark, light or the phone's, each a little phone drawn in that
/// look. Tapping one applies it to the whole app at once (the screen it's on
/// changes around it). Used by the onboarding and Settings.
class ThemeModePicker extends StatelessWidget {
  const ThemeModePicker({super.key});

  static const _options = [
    (ThemeMode.dark, Icons.dark_mode_rounded, AppStrings.themeDark),
    (ThemeMode.light, Icons.light_mode_rounded, AppStrings.themeLight),
    (
      ThemeMode.system,
      Icons.brightness_auto_rounded,
      AppStrings.onboardingAuto,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;
    final phoneDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (value, icon, label) in _options)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.r),
            child: _ThemeCard(
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

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.icon,
    required this.label,
    required this.dark,
    required this.split,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool dark;

  /// Half dark, half light (follows the phone).
  final bool split;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.06 : 0.96,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(
                    color: selected ? accent : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 20,
                          ),
                        ]
                      : const [],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18.r),
                      child: SizedBox(
                        width: 82.r,
                        height: 150.r,
                        child: split
                            ? Row(
                                children: [
                                  Expanded(
                                    child: ClipRect(
                                      child: OverflowBox(
                                        alignment: Alignment.centerLeft,
                                        maxWidth: 82.r,
                                        child: _MiniPhone(
                                          dark: true,
                                          accent: accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: ClipRect(
                                      child: OverflowBox(
                                        alignment: Alignment.centerRight,
                                        maxWidth: 82.r,
                                        child: _MiniPhone(
                                          dark: false,
                                          accent: accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : _MiniPhone(dark: dark, accent: accent),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        right: -8.r,
                        top: -8.r,
                        child: Container(
                          padding: EdgeInsets.all(3.r),
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 16.r,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 12.r),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16.r,
                    color: selected
                        ? accent
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  SizedBox(width: 4.r),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: selected
                          ? FontWeightHelper.bold
                          : FontWeightHelper.medium,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tiny Melodix screen: a header, a few song rows and the music bar.
class _MiniPhone extends StatelessWidget {
  const _MiniPhone({required this.dark, required this.accent});

  final bool dark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final background = dark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final ink = dark ? Colors.white : const Color(0xFF1A1A1A);
    Widget line(double width, double alpha) => Container(
      width: width,
      height: 5.r,
      decoration: BoxDecoration(
        color: ink.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(3),
      ),
    );
    return Container(
      width: 82.r,
      color: background,
      padding: EdgeInsets.fromLTRB(8.r, 12.r, 8.r, 8.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(36.r, 0.85),
          SizedBox(height: 10.r),
          for (var i = 0; i < 4; i++) ...[
            Row(
              children: [
                Container(
                  width: 14.r,
                  height: 14.r,
                  decoration: BoxDecoration(
                    color: i == 0 ? accent : ink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(width: 5.r),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    line(34.r - i * 3, 0.6),
                    SizedBox(height: 3.r),
                    line(22.r, 0.3),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.r),
          ],
          const Spacer(),
          Container(
            height: 20.r,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF242424) : Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 5.r),
            child: Row(
              children: [
                line(28.r, 0.5),
                const Spacer(),
                Icon(Icons.play_arrow_rounded, size: 12.r, color: accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
