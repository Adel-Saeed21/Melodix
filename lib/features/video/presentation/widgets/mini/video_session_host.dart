import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/service/picture_in_picture_service.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/mini/mini_video_window.dart';
import 'package:melodix/features/video/presentation/widgets/mini/picture_in_picture_auto_enter.dart';
import 'package:melodix/features/video/presentation/widgets/mini/picture_in_picture_video.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_transport_buttons.dart';
import 'package:melodix/features/video/presentation/widgets/player/keep_screen_on.dart';

/// Wraps the whole app (every page) with the video session's pieces:
/// * the small video window, while a video is open but the full player
///   isn't showing;
/// * picture-in-picture (with [pictureInPicture]): leaving the app while a
///   video plays keeps it going in a window over other apps, which shows
///   only the video; its back / play-pause / forward buttons control the
///   video;
/// * the screen kept on while the video plays;
/// * listened to as audio ([VideoPlayerState.audioOnly]): no picture-in-
///   picture and the screen may sleep; the small window shows the audio
///   controls instead, and it keeps playing with the app hidden (watched,
///   it pauses then, and plays on when the app is back).
///
/// The music mini player stays where it is; the small window keeps clear
/// of it ([clearance]).
class VideoSessionHost extends StatefulWidget {
  const VideoSessionHost({
    super.key,
    required this.child,
    required this.onExpand,
    this.pictureInPicture,
    this.clearance = MiniVideoWindow.portraitClearance,
  });

  /// The app's pages.
  final Widget child;

  /// Shows the full-screen player.
  final VoidCallback onExpand;

  /// Null: no picture-in-picture (e.g. in tests).
  final PictureInPictureService? pictureInPicture;

  /// Room the small window leaves for the app's bars (the nav bar or rail,
  /// and the music mini player when there's a song).
  final EdgeInsets clearance;

  @override
  State<VideoSessionHost> createState() => _VideoSessionHostState();
}

class _VideoSessionHostState extends State<VideoSessionHost> {
  bool _inPip = false;
  StreamSubscription<bool>? _pipChanges;
  StreamSubscription<PictureInPictureAction>? _pipActions;

  /// The app hidden / shown: a watched video pauses and plays on (see
  /// [VideoPlayerCubit.appHidden]).
  late final AppLifecycleListener _lifecycle;

  /// The screen as it was before the window: the pages keep that layout
  /// while hidden (laid out in a thumbnail-sized window they'd squash).
  MediaQueryData? _fullScreen;

  @override
  void initState() {
    super.initState();
    _pipChanges = widget.pictureInPicture?.modeChanges.listen((inPip) {
      if (mounted && inPip != _inPip) setState(() => _inPip = inPip);
    });
    _pipActions = widget.pictureInPicture?.actions.listen(_onPipAction);
    final session = context.read<VideoPlayerCubit>();
    // Paused: really out of sight (picture-in-picture is only inactive).
    _lifecycle = AppLifecycleListener(
      onPause: () => unawaited(session.appHidden()),
      onResume: () => unawaited(session.appShown()),
    );
  }

  /// A button in the picture-in-picture window.
  void _onPipAction(PictureInPictureAction action) {
    if (!mounted) return;
    final session = context.read<VideoPlayerCubit>();
    final step = videoSeekStepOf(context);
    unawaited(switch (action) {
      PictureInPictureAction.rewind => session.seekBy(-step),
      PictureInPictureAction.forward => session.seekBy(step),
      PictureInPictureAction.pause => session.pause(),
      PictureInPictureAction.play =>
        // Only if it's paused (the button may lag a tap behind).
        session.state.engine?.value.isPlaying ?? true
            ? Future<void>.value()
            : session.togglePlayPause(),
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _pipChanges?.cancel();
    _pipActions?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_inPip) _fullScreen = MediaQuery.of(context);
    final pip = widget.pictureInPicture;
    return BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
      buildWhen: (p, c) =>
          p.isActive != c.isActive ||
          p.expanded != c.expanded ||
          p.audioOnly != c.audioOnly ||
          p.engine != c.engine ||
          p.status != c.status ||
          p.index != c.index ||
          p.queue != c.queue,
      builder: (context, state) {
        final engine = state.isActive ? state.engine : null;
        // Listened to as audio, nothing shows the picture.
        final picture = state.audioOnly ? null : engine;
        final showPip = _inPip && picture != null;
        return Stack(
          fit: StackFit.expand,
          children: [
            // In the window: the pages stay alive (and as they were),
            // just not drawn.
            Offstage(
              offstage: showPip,
              child: TickerMode(
                enabled: !showPip,
                // Always the same widgets around the pages (only the
                // data changes), so they're never rebuilt from scratch.
                child: MediaQuery(
                  data: showPip ? _fullScreen! : MediaQuery.of(context),
                  child: widget.child,
                ),
              ),
            ),
            if (picture != null)
              Positioned(left: 0, top: 0, child: KeepScreenOn(engine: picture)),
            if (pip != null && state.isActive)
              Positioned(
                left: 0,
                top: 0,
                child: PictureInPictureAutoEnter(
                  service: pip,
                  engine: picture,
                  video: state.video,
                ),
              ),
            if (showPip)
              Positioned.fill(child: PictureInPictureVideo(engine: picture))
            else if (state.isActive && !state.expanded)
              MiniVideoWindow(
                state: state,
                onExpand: widget.onExpand,
                clearance: widget.clearance,
                onClose: context.read<VideoPlayerCubit>().stop,
              ),
          ],
        );
      },
    );
  }
}
