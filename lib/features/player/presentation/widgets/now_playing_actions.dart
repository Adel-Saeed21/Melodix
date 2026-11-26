import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/features/player/presentation/logic/audio_settings_cubit.dart';
import 'package:melodix/features/player/presentation/logic/sleep_timer_cubit.dart';
import 'package:melodix/features/player/presentation/widgets/player_queue_sheet.dart';
import 'package:melodix/features/player/presentation/widgets/sleep_timer_sheet.dart';

/// The row under the controls on Now Playing: lyrics, sleep timer, speed
/// and the queue. Each lights up in the accent while it's in use.
class NowPlayingActions extends StatelessWidget {
  const NowPlayingActions({
    super.key,
    required this.showingLyrics,
    required this.onLyrics,
  });

  final bool showingLyrics;
  final VoidCallback onLyrics;

  @override
  Widget build(BuildContext context) {
    final sleep = context.watch<SleepTimerCubit>().state;
    final speed = context.select<AudioSettingsCubit, double>(
      (c) => c.state.speed,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Action(
          icon: Icons.lyrics_rounded,
          label: AppStrings.lyrics,
          tooltip: showingLyrics ? AppStrings.showCover : AppStrings.showLyrics,
          active: showingLyrics,
          onTap: onLyrics,
        ),
        _Action(
          icon: Icons.bedtime_rounded,
          label: switch (sleep) {
            SleepTimerState(:final remaining?) => formatDuration(remaining),
            SleepTimerState(endOfSong: true) => AppStrings.sleepTimerEndOfSong,
            _ => AppStrings.sleepTimer,
          },
          tooltip: AppStrings.sleepTimer,
          active: sleep.isActive,
          onTap: () => showSleepTimerSheet(context),
        ),
        _Action(
          icon: Icons.speed_rounded,
          label: AppStrings.speedValue(speed),
          tooltip: AppStrings.speed,
          active: speed != 1,
          onTap: () => showSpeedSheet(context),
        ),
        _Action(
          icon: Icons.queue_music_rounded,
          label: AppStrings.queue,
          tooltip: AppStrings.queue,
          active: false,
          onTap: () => showPlayerQueue(context),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? theme.primaryColor
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 32.r,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 6.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? theme.primaryColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                  ),
                  child: Icon(icon, size: 22.r, color: color),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: AppTextSizes.xs,
                      fontWeight: active
                          ? FontWeightHelper.bold
                          : FontWeightHelper.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Speed choices and skip silence.
Future<void> showSpeedSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (_) => BlocProvider.value(
    value: context.read<AudioSettingsCubit>(),
    child: const _SpeedSheet(),
  ),
);

class _SpeedSheet extends StatelessWidget {
  const _SpeedSheet();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AudioSettingsCubit>();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.speed,
              style: TextStyle(
                color: onSurface,
                fontSize: AppTextSizes.xl,
                fontWeight: FontWeightHelper.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.r,
              runSpacing: 8.r,
              children: [
                for (final speed in AudioSettings.speeds)
                  ChoiceChip(
                    label: Text(AppStrings.speedValue(speed)),
                    selected: settings.state.speed == speed,
                    onSelected: (_) => settings.setSpeed(speed),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.skipSilence),
              subtitle: const Text(AppStrings.skipSilenceHint),
              value: settings.state.skipSilence,
              onChanged: settings.setSkipSilence,
            ),
          ],
        ),
      ),
    );
  }
}
