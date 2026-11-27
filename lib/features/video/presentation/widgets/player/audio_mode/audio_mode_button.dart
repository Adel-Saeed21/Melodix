import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';

/// Switches between watching the video and listening to it as audio (the
/// same playback carries on; see [VideoPlayerState.audioOnly]).
class AudioModeButton extends StatelessWidget {
  const AudioModeButton({super.key, this.onTouched});

  /// Pressed: keep the controls up a little longer.
  final VoidCallback? onTouched;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<VideoPlayerCubit, VideoPlayerState, bool>(
      selector: (s) => s.audioOnly,
      builder: (context, audioOnly) => IconButton(
        tooltip: audioOnly
            ? context.l10n.watchVideo
            : context.l10n.listenAsAudio,
        color: Colors.white,
        onPressed: () {
          onTouched?.call();
          context.read<VideoPlayerCubit>().toggleAudioOnly();
        },
        icon: Icon(
          audioOnly ? Icons.ondemand_video_rounded : Icons.headphones_rounded,
        ),
      ),
    );
  }
}
