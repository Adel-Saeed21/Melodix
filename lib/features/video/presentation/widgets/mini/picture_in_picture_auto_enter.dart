import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/service/picture_in_picture_service.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';

/// Keeps Android's picture-in-picture in step with the video: leaving the
/// app shrinks it into a window over other apps only while a video is
/// playing (paused, closed or no video: leaving works as usual). The
/// window takes the video's shape.
class PictureInPictureAutoEnter extends StatefulWidget {
  const PictureInPictureAutoEnter({
    super.key,
    required this.service,
    required this.engine,
    required this.video,
  });

  final PictureInPictureService service;

  /// Null while the video loads (or failed): no window then.
  final VideoEngine? engine;
  final Video video;

  @override
  State<PictureInPictureAutoEnter> createState() =>
      _PictureInPictureAutoEnterState();
}

class _PictureInPictureAutoEnterState extends State<PictureInPictureAutoEnter> {
  /// What the platform was last told, so it's only told about changes
  /// (the player reports its position several times a second).
  (bool, int, int)? _sent;

  @override
  void initState() {
    super.initState();
    widget.engine?.addListener(_update);
    _update();
  }

  @override
  void didUpdateWidget(PictureInPictureAutoEnter old) {
    super.didUpdateWidget(old);
    if (old.engine != widget.engine) {
      old.engine?.removeListener(_update);
      widget.engine?.addListener(_update);
    }
    _update();
  }

  void _update() {
    final value = widget.engine?.value;
    final playing = value != null && value.isInitialized && value.isPlaying;
    final size = value != null && value.isInitialized && !value.size.isEmpty
        ? value.size
        : Size(widget.video.width.toDouble(), widget.video.height.toDouble());
    _send((playing, size.width.round(), size.height.round()));
  }

  void _send((bool, int, int) wanted) {
    if (wanted == _sent) return;
    _sent = wanted;
    final (enabled, width, height) = wanted;
    // Playing: auto-enter on, and the window's middle button is pause.
    widget.service.setAutoEnter(
      enabled: enabled,
      playing: enabled,
      width: width,
      height: height,
    );
  }

  @override
  void dispose() {
    widget.engine?.removeListener(_update);
    // No video any more: leaving the app just leaves it.
    final sent = _sent;
    if (sent != null && sent.$1) _send((false, sent.$2, sent.$3));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
