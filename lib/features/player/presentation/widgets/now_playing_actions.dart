import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/features/player/presentation/logic/audio_settings_cubit.dart';
import 'package:melodix/features/player/presentation/logic/sleep_timer_cubit.dart';
import 'package:melodix/features/player/presentation/widgets/player_queue_sheet.dart';
import 'package:melodix/features/player/presentation/widgets/sleep_timer_sheet.dart';
import 'package:melodix/features/player/presentation/widgets/now_playing_actions/now_playing_action_button.dart';
import 'package:melodix/features/player/presentation/widgets/now_playing_actions/playback_speed_sheet.dart';

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
        NowPlayingActionButton(
          icon: Icons.lyrics_rounded,
          label: context.l10n.lyrics,
          tooltip: showingLyrics
              ? context.l10n.showCover
              : context.l10n.showLyrics,
          active: showingLyrics,
          onTap: onLyrics,
        ),
        NowPlayingActionButton(
          icon: Icons.bedtime_rounded,
          label: switch (sleep) {
            SleepTimerState(:final remaining?) => formatDuration(remaining),
            SleepTimerState(endOfSong: true) =>
              context.l10n.sleepTimerEndOfSong,
            _ => context.l10n.sleepTimer,
          },
          tooltip: context.l10n.sleepTimer,
          active: sleep.isActive,
          onTap: () => showSleepTimerSheet(context),
        ),
        NowPlayingActionButton(
          icon: Icons.speed_rounded,
          label: context.l10n.speedValue(speed),
          tooltip: context.l10n.speed,
          active: speed != 1,
          onTap: () => showSpeedSheet(context),
        ),
        NowPlayingActionButton(
          icon: Icons.queue_music_rounded,
          label: context.l10n.queue,
          tooltip: context.l10n.queue,
          active: false,
          onTap: () => showPlayerQueue(context),
        ),
      ],
    );
  }
}

/// Speed choices and skip silence.
Future<void> showSpeedSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (_) => BlocProvider.value(
    value: context.read<AudioSettingsCubit>(),
    child: const PlaybackSpeedSheet(),
  ),
);
