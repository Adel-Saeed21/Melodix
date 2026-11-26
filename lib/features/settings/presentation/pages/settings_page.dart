import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/core/widgets/melodix_mark.dart';
import 'package:melodix/core/widgets/theme_mode_picker.dart';
import 'package:melodix/features/settings/presentation/widgets/accent_swatches.dart';
import 'package:melodix/features/settings/presentation/widgets/feature_rows.dart';
import 'package:melodix/features/settings/presentation/widgets/pill_choices.dart';
import 'package:melodix/features/settings/presentation/widgets/preview_choices.dart';
import 'package:melodix/features/settings/presentation/widgets/settings_header.dart';
import 'package:melodix/features/settings/presentation/widgets/settings_section.dart';

/// Settings: the app's plain background, a header like the other tabs',
/// and each choice shown as what it looks like (the theme as little
/// phones, the music bar and selection actions drawn). Changes apply at
/// once.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16.w + padding.left,
              padding.top,
              16.w + padding.right,
              padding.bottom + 24.h,
            ),
            sliver: SliverList.list(
              children: const [
                SettingsHeader(),
                SettingsSection(
                  icon: Icons.palette_outlined,
                  title: AppStrings.appearance,
                  children: [
                    _ThemeChoice(),
                    _AccentChoice(),
                    NowPlayingBackgroundChoice(),
                    AppIconRow(),
                  ],
                ),
                SettingsSection(
                  icon: Icons.dashboard_customize_outlined,
                  title: AppStrings.layout,
                  children: [_MusicBarChoice(), _SelectionBarChoice()],
                ),
                SettingsSection(
                  icon: Icons.headphones_outlined,
                  title: AppStrings.playback,
                  children: [
                    SpeedChoice(),
                    SkipSilenceRow(),
                    EqualizerRow(),
                    SleepTimerRow(),
                  ],
                ),
                SettingsSection(
                  icon: Icons.smart_display_outlined,
                  title: AppStrings.videoSettings,
                  children: [_VideoSkipChoice(), SubtitleStyleChoice()],
                ),
                SettingsSection(
                  icon: Icons.library_music_outlined,
                  title: AppStrings.library,
                  children: [ListeningStatsRow(), LibraryFiltersRow()],
                ),
                _Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark / light / the phone's, as the onboarding shows them.
class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice();

  @override
  Widget build(BuildContext context) {
    return const SettingRow(
      title: AppStrings.theme,
      below: FittedBox(fit: BoxFit.scaleDown, child: ThemeModePicker()),
    );
  }
}

class _AccentChoice extends StatelessWidget {
  const _AccentChoice();

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UiPreferencesCubit>();
    final state = preferences.state;
    return SettingRow(
      title: AppStrings.accentColour,
      subtitle: state.dynamicAccent
          ? AppStrings.coverColoursHint
          : state.accent.label,
      below: AccentSwatches(
        value: state.accent,
        fromCover: state.dynamicAccent,
        onChanged: preferences.setAccent,
        onFromCover: () => preferences.setDynamicAccent(true),
      ),
    );
  }
}

class _MusicBarChoice extends StatelessWidget {
  const _MusicBarChoice();

  static const _hints = {
    MiniPlayerStyle.classic: AppStrings.miniPlayerClassicHint,
    MiniPlayerStyle.capsule: AppStrings.miniPlayerCapsuleHint,
    MiniPlayerStyle.minimal: AppStrings.miniPlayerMinimalHint,
  };

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UiPreferencesCubit>();
    final current = preferences.state.miniPlayer;
    return SettingRow(
      title: AppStrings.miniPlayerStyle,
      subtitle: _hints[current],
      below: PreviewChoices<MiniPlayerStyle>(
        value: current,
        onChanged: preferences.setMiniPlayer,
        options: [
          for (final (style, name) in const [
            (MiniPlayerStyle.classic, AppStrings.miniPlayerClassic),
            (MiniPlayerStyle.capsule, AppStrings.miniPlayerCapsule),
            (MiniPlayerStyle.minimal, AppStrings.miniPlayerMinimal),
          ])
            PreviewOption(style, name, (_) => MusicBarPreview(style)),
        ],
      ),
    );
  }
}

class _SelectionBarChoice extends StatelessWidget {
  const _SelectionBarChoice();

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UiPreferencesCubit>();
    return SettingRow(
      title: AppStrings.selectionBarStyle,
      subtitle: AppStrings.selectionBarHint,
      below: PreviewChoices<SelectionBarStyle>(
        value: preferences.state.selectionBar,
        onChanged: preferences.setSelectionBar,
        options: [
          for (final (style, name) in const [
            (SelectionBarStyle.bottom, AppStrings.selectionBarBottom),
            (SelectionBarStyle.side, AppStrings.selectionBarSide),
          ])
            PreviewOption(style, name, (_) => SelectionBarPreview(style)),
        ],
      ),
    );
  }
}

/// How far the video player's skip buttons and double-taps jump.
class _VideoSkipChoice extends StatelessWidget {
  const _VideoSkipChoice();

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UiPreferencesCubit>();
    return SettingRow(
      title: AppStrings.videoSkip,
      subtitle: AppStrings.videoSkipHint,
      below: PillChoices<int>(
        value: preferences.state.videoSeekSeconds,
        onChanged: preferences.setVideoSeekSeconds,
        options: [
          for (final seconds in UiPreferences.videoSeekChoices)
            (seconds, AppStrings.videoSkipSeconds(seconds)),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final faint = theme.colorScheme.onSurface.withValues(alpha: 0.4);
    return Padding(
      padding: EdgeInsets.only(top: 32.h, bottom: 8.h),
      child: Column(
        children: [
          MelodixMark(size: 28.r, color: theme.primaryColor),
          SizedBox(height: 8.h),
          Text(
            AppStrings.appName,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: AppTextSizes.base,
              fontWeight: FontWeightHelper.bold,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            AppStrings.settingsFooter,
            style: TextStyle(color: faint, fontSize: AppTextSizes.sm),
          ),
        ],
      ),
    );
  }
}
