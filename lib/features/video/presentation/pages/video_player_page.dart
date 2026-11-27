import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/widgets/drag_to_dismiss.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/player/audio_mode/video_audio_view.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_loading_view.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_playback_error_view.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_playing_view.dart';

/// Full-screen video player: black, edge to edge, system bars hidden.
/// Opens in the phone's normal (portrait) position; only the rotate button
/// turns it sideways, and that choice stays for the next videos.
/// Shows the app's video session (see [VideoPlayerCubit]): leaving it
/// doesn't stop the video, which carries on in the small window.
///
/// Pull it down (or tap ⌄) to minimize it to the small window.
///
/// Listened to as audio, it's a now-playing screen instead: system bars
/// shown, upright; back to the video, the user's look and turn come back.
class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final VideoPlayerCubit _session;
  bool _landscape = false;

  @override
  void initState() {
    super.initState();
    _session = context.read<VideoPlayerCubit>()..setExpanded(true);
    _applyMode(audioOnly: _session.state.audioOnly);
  }

  /// Watched: full screen, bars hidden, turned as the user chose.
  /// Listened to: bars shown, upright.
  void _applyMode({required bool audioOnly}) {
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        audioOnly ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
      ),
    );
    _setOrientation(landscape: !audioOnly && _landscape);
  }

  void _setLandscape(bool landscape) {
    _landscape = landscape;
    _setOrientation(landscape: landscape);
  }

  void _setOrientation({required bool landscape}) {
    unawaited(
      SystemChrome.setPreferredOrientations(
        landscape
            ? const [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]
            : const [DeviceOrientation.portraitUp],
      ),
    );
  }

  @override
  void dispose() {
    _session.setExpanded(false);
    // Back to the app's normal look: bars shown, any orientation.
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(SystemChrome.setPreferredOrientations(const []));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      // Pull down anywhere to minimize (locked controls ignore it).
      child: DragToDismiss(
        onDismiss: () => Navigator.of(context).maybePop(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: BlocConsumer<VideoPlayerCubit, VideoPlayerState>(
            // The video was closed. (A new video never rotates the screen:
            // the orientation is the user's choice.)
            // Or switched between watching and listening.
            listenWhen: (p, c) =>
                (p.isActive && !c.isActive) ||
                (c.isActive && p.audioOnly != c.audioOnly),
            listener: (context, state) {
              if (!state.isActive) {
                Navigator.of(context).maybePop();
              } else {
                _applyMode(audioOnly: state.audioOnly);
              }
            },
            buildWhen: (p, c) =>
                p.status != c.status ||
                p.audioOnly != c.audioOnly ||
                p.engine != c.engine ||
                p.index != c.index ||
                p.queue != c.queue,
            builder: (context, state) => switch (state.status) {
              VideoPlayerStatus.idle => const SizedBox.shrink(),
              VideoPlayerStatus.loading => VideoLoadingView(video: state.video),
              VideoPlayerStatus.failed => VideoPlaybackErrorView(state: state),
              VideoPlayerStatus.ready when state.audioOnly => VideoAudioView(
                engine: state.engine!,
              ),
              VideoPlayerStatus.ready => VideoPlayingView(
                engine: state.engine!,
                onRotate: () => _setLandscape(!_landscape),
              ),
            },
          ),
        ),
      ),
    );
  }
}
