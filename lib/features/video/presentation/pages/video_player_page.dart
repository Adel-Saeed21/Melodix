import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_loading_view.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_playback_error_view.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_playing_view.dart';

/// Full-screen video player: black, edge to edge, system bars hidden.
/// Opens in the phone's normal (portrait) position; only the rotate button
/// turns it sideways, and that choice stays for the next videos.
/// Shows the app's video session (see [VideoPlayerCubit]): leaving it
/// doesn't stop the video, which carries on in the small window.
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
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    _setLandscape(false);
  }

  void _setLandscape(bool landscape) {
    _landscape = landscape;
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
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocConsumer<VideoPlayerCubit, VideoPlayerState>(
          // The video was closed. (A new video never rotates the screen:
          // the orientation is the user's choice.)
          listenWhen: (p, c) => p.isActive && !c.isActive,
          listener: (context, state) => Navigator.of(context).maybePop(),
          buildWhen: (p, c) =>
              p.status != c.status ||
              p.engine != c.engine ||
              p.index != c.index ||
              p.queue != c.queue,
          builder: (context, state) => switch (state.status) {
            VideoPlayerStatus.idle => const SizedBox.shrink(),
            VideoPlayerStatus.loading => VideoLoadingView(video: state.video),
            VideoPlayerStatus.failed => VideoPlaybackErrorView(state: state),
            VideoPlayerStatus.ready => VideoPlayingView(
              engine: state.engine!,
              onRotate: () => _setLandscape(!_landscape),
            ),
          },
        ),
      ),
    );
  }
}
