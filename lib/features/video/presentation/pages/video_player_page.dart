import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/navigation/video_player_navigation.dart';
import 'package:melodix/features/video/presentation/widgets/player/keep_screen_on.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_loading_view.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_playback_error_view.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_playing_view.dart';

/// Full-screen video player: black, edge to edge, system bars hidden.
/// Turns to the video's shape (landscape videos play sideways) and keeps
/// the screen on only while a video is playing.
class VideoPlayerPage extends StatelessWidget {
  const VideoPlayerPage({super.key, required this.args, this.createCubit});

  final VideoPlayerArgs args;

  /// Tests pass their own; otherwise the app's (from get_it).
  final VideoPlayerCubit Function(VideoPlayerArgs args)? createCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          (createCubit?.call(args) ?? getIt<VideoPlayerCubit>(param1: args))
            ..start(),
      child: const _PlayerScreen(),
    );
  }
}

class _PlayerScreen extends StatefulWidget {
  const _PlayerScreen();

  @override
  State<_PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<_PlayerScreen> {
  bool _landscape = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    _fitTo(context.read<VideoPlayerCubit>().state.video);
  }

  /// Landscape for wide videos, portrait for tall ones.
  void _fitTo(Video video) {
    _setLandscape(video.width > video.height);
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
    // Back to the app's normal look: bars shown, any orientation.
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(SystemChrome.setPreferredOrientations(const []));
    keepScreenOn(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocConsumer<VideoPlayerCubit, VideoPlayerState>(
          listenWhen: (p, c) => p.index != c.index,
          listener: (context, state) => _fitTo(state.video),
          buildWhen: (p, c) =>
              p.status != c.status ||
              p.controller != c.controller ||
              p.index != c.index,
          builder: (context, state) => switch (state.status) {
            VideoPlayerStatus.loading => VideoLoadingView(video: state.video),
            VideoPlayerStatus.failed => VideoPlaybackErrorView(state: state),
            VideoPlayerStatus.ready => VideoPlayingView(
              controller: state.controller!,
              onRotate: () => _setLandscape(!_landscape),
            ),
          },
        ),
      ),
    );
  }
}
