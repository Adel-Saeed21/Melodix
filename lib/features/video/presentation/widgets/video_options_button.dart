import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/core/widgets/options_menu.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/navigation/video_player_navigation.dart';
import 'package:melodix/features/video/presentation/widgets/video_delete_action.dart';

enum _VideoOption { playNext, addToQueue, delete }

/// The ⋮ button on a video row: play next, add to the list playing, or
/// delete from the phone (same menu style as songs).
class VideoOptionsButton extends StatelessWidget {
  const VideoOptionsButton({super.key, required this.video});

  final Video video;

  Future<void> _onSelected(BuildContext context, _VideoOption option) async {
    final session = context.read<VideoPlayerCubit>();
    switch (option) {
      case _VideoOption.playNext:
      case _VideoOption.addToQueue:
        final next = option == _VideoOption.playNext;
        final started = next
            ? session.playNext([video])
            : session.addToQueue([video]);
        if (started) {
          // Nothing was playing: it plays now, in the player.
          showVideoPlayer(context);
        } else {
          AppSnackBar.show(
            context,
            next ? context.l10n.playsNext(1) : context.l10n.addedToQueue(1),
          );
        }
      case _VideoOption.delete:
        await deleteVideosAsking(context, [video.id]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OptionsMenuButton<_VideoOption>(
      tooltip: context.l10n.videoOptions,
      padding: EdgeInsets.zero,
      onSelected: (option) => _onSelected(context, option),
      itemBuilder: (context) => [
        optionsMenuItem(
          context,
          value: _VideoOption.playNext,
          icon: Icons.playlist_play_rounded,
          label: context.l10n.playNext,
        ),
        optionsMenuItem(
          context,
          value: _VideoOption.addToQueue,
          icon: Icons.queue_play_next_rounded,
          label: context.l10n.addToQueue,
        ),
        const PopupMenuDivider(),
        optionsMenuItem(
          context,
          value: _VideoOption.delete,
          icon: Icons.delete_outline_rounded,
          label: context.l10n.deleteFromPhone,
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }
}
