import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/widgets/player/controller_selector.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Screen stays on while playing; paused, it may sleep as usual.
class KeepScreenOn extends StatelessWidget {
  const KeepScreenOn({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ControllerSelector<bool>(
      controller: controller,
      select: (v) => v.isPlaying,
      builder: (context, playing) {
        keepScreenOn(playing);
        return const SizedBox.shrink();
      },
    );
  }
}

/// Best effort: if the screen can't be kept on, the video still plays.
void keepScreenOn(bool on) {
  unawaited(WakelockPlus.toggle(enable: on).catchError((Object _) {}));
}
