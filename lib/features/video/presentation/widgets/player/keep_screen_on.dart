import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Screen stays on while the video plays (full screen or in the small
/// window); paused or gone, it may sleep as usual.
class KeepScreenOn extends StatefulWidget {
  const KeepScreenOn({super.key, required this.engine});

  final VideoEngine engine;

  @override
  State<KeepScreenOn> createState() => _KeepScreenOnState();
}

class _KeepScreenOnState extends State<KeepScreenOn> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    widget.engine.addListener(_update);
    _update();
  }

  @override
  void didUpdateWidget(KeepScreenOn old) {
    super.didUpdateWidget(old);
    if (old.engine != widget.engine) {
      old.engine.removeListener(_update);
      widget.engine.addListener(_update);
      _update();
    }
  }

  void _update() {
    final playing = widget.engine.value.isPlaying;
    if (playing == _on) return;
    _on = playing;
    keepScreenOn(playing);
  }

  @override
  void dispose() {
    widget.engine.removeListener(_update);
    if (_on) keepScreenOn(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Best effort: if the screen can't be kept on, the video still plays.
void keepScreenOn(bool on) {
  unawaited(WakelockPlus.toggle(enable: on).catchError((Object _) {}));
}
