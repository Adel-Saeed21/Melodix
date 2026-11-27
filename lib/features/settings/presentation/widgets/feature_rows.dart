import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/core/service/app_icon_service.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/features/player/presentation/logic/audio_settings_cubit.dart';
import 'package:melodix/features/player/presentation/logic/sleep_timer_cubit.dart';
import 'package:melodix/features/player/presentation/widgets/sleep_timer_sheet.dart';
import 'package:melodix/features/settings/presentation/widgets/app_icon_picker.dart';
import 'package:melodix/features/settings/presentation/widgets/pill_choices.dart';
import 'package:melodix/features/settings/presentation/widgets/preview_choices.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';
import 'package:melodix/features/subtitles/presentation/widgets/subtitle_text.dart';

// Appearance

/// The home-screen icon (Android only: nothing elsewhere).
class AppIconRow extends StatelessWidget {
  const AppIconRow({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.read<AppIconCubit>().isSupported) {
      return const SizedBox.shrink();
    }
    return SettingRow(
      title: context.l10n.appIcon,
      subtitle: context.l10n.appIconHint,
      below: AppIconPicker(),
    );
  }
}

class NowPlayingBackgroundChoice extends StatelessWidget {
  const NowPlayingBackgroundChoice({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UiPreferencesCubit>();
    return SettingRow(
      title: context.l10n.nowPlayingBackground,
      below: PreviewChoices<NowPlayingBackground>(
        value: preferences.state.nowPlayingBackground,
        onChanged: preferences.setNowPlayingBackground,
        previewHeight: 52,
        options: [
          for (final (value, icon, name) in [
            (
              NowPlayingBackground.plain,
              Icons.crop_square_rounded,
              context.l10n.backgroundPlain,
            ),
            (
              NowPlayingBackground.cover,
              Icons.album_rounded,
              context.l10n.backgroundCover,
            ),
            (
              NowPlayingBackground.glow,
              Icons.blur_on_rounded,
              context.l10n.backgroundGlow,
            ),
          ])
            PreviewOption(
              value,
              name,
              (selected) => IconPreview(icon, selected: selected),
            ),
        ],
      ),
    );
  }
}

// Playback

class SpeedChoice extends StatelessWidget {
  const SpeedChoice({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AudioSettingsCubit>();
    return SettingRow(
      title: context.l10n.speed,
      subtitle: context.l10n.speedHint,
      below: PillChoices<double>(
        value: settings.state.speed,
        onChanged: settings.setSpeed,
        options: [
          for (final speed in AudioSettings.speeds)
            (speed, context.l10n.speedValue(speed)),
        ],
      ),
    );
  }
}

class SkipSilenceRow extends StatelessWidget {
  const SkipSilenceRow({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AudioSettingsCubit>();
    return SettingRow(
      leading: Icons.graphic_eq_rounded,
      title: context.l10n.skipSilence,
      subtitle: context.l10n.skipSilenceHint,
      onTap: () => settings.setSkipSilence(!settings.state.skipSilence),
      trailing: Switch(
        value: settings.state.skipSilence,
        onChanged: settings.setSkipSilence,
      ),
    );
  }
}

class EqualizerRow extends StatelessWidget {
  const EqualizerRow({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AudioSettingsCubit>().state;
    return SettingRow(
      leading: Icons.equalizer_rounded,
      title: context.l10n.equalizer,
      subtitle: state.equalizerOn
          ? state.preset.label
          : context.l10n.equalizerHint,
      trailing: const RowChevron(),
      onTap: () => context.pushNamed(Routes.equalizer),
    );
  }
}

class SleepTimerRow extends StatelessWidget {
  const SleepTimerRow({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SleepTimerCubit>().state;
    return SettingRow(
      leading: Icons.bedtime_rounded,
      title: context.l10n.sleepTimer,
      subtitle: switch (state) {
        SleepTimerState(:final remaining?) => context.l10n.sleepTimerLeft(
          formatDuration(remaining),
        ),
        SleepTimerState(endOfSong: true) => context.l10n.sleepTimerStopsAtEnd,
        _ => context.l10n.sleepTimerHint,
      },
      trailing: const RowChevron(),
      onTap: () => showSleepTimerSheet(context),
    );
  }
}

// Subtitles

/// Size, style and colour, with a caption drawn over a little "video" as
/// it will look.
class SubtitleStyleChoice extends StatelessWidget {
  const SubtitleStyleChoice({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UiPreferencesCubit>();
    final state = preferences.state;
    final (accent, second) = accentPair(context);
    Widget label(String text) => Padding(
      padding: EdgeInsets.only(top: 12.h, bottom: 6.h),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 12.sp,
        ),
      ),
    );
    return SettingRow(
      title: context.l10n.subtitleStyle,
      below: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The preview: a dusky "scene" with the caption on it.
          ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              height: 110.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [
                    Color.lerp(accent, Colors.black, 0.55)!,
                    Color.lerp(second, Colors.black, 0.75)!,
                  ],
                ),
              ),
              child: SubtitleText(
                text: context.l10n.subtitlePreview,
                style: state,
                padding: EdgeInsetsDirectional.fromSTEB(12.w, 0, 12.w, 14.h),
              ),
            ),
          ),
          label(context.l10n.subtitleSize),
          PillChoices<SubtitleSize>(
            value: state.subtitleSize,
            onChanged: preferences.setSubtitleSize,
            options: [
              (SubtitleSize.small, context.l10n.subtitleSmall),
              (SubtitleSize.medium, context.l10n.subtitleMedium),
              (SubtitleSize.large, context.l10n.subtitleLarge),
              (SubtitleSize.huge, context.l10n.subtitleHuge),
            ],
          ),
          label(context.l10n.subtitleLook),
          PillChoices<SubtitleLook>(
            value: state.subtitleLook,
            onChanged: preferences.setSubtitleLook,
            options: [
              (SubtitleLook.box, context.l10n.subtitleBox),
              (SubtitleLook.outline, context.l10n.subtitleOutline),
            ],
          ),
          label(context.l10n.subtitleColour),
          PillChoices<SubtitleColor>(
            value: state.subtitleColor,
            onChanged: preferences.setSubtitleColor,
            options: [
              (SubtitleColor.white, context.l10n.subtitleWhite),
              (SubtitleColor.yellow, context.l10n.subtitleYellow),
              (SubtitleColor.accent, context.l10n.subtitleAccent),
            ],
          ),
        ],
      ),
    );
  }
}

// Library

class ListeningStatsRow extends StatelessWidget {
  const ListeningStatsRow({super.key});

  @override
  Widget build(BuildContext context) => SettingRow(
    leading: Icons.insights_rounded,
    title: context.l10n.yourMelodix,
    subtitle: context.l10n.yourMelodixHint,
    trailing: const RowChevron(),
    onTap: () => context.pushNamed(Routes.listeningStats),
  );
}

class LibraryFiltersRow extends StatelessWidget {
  const LibraryFiltersRow({super.key});

  @override
  Widget build(BuildContext context) => SettingRow(
    leading: Icons.filter_alt_rounded,
    title: context.l10n.libraryFilters,
    subtitle: context.l10n.libraryFiltersHint,
    trailing: const RowChevron(),
    onTap: () => context.pushNamed(Routes.libraryFilters),
  );
}
