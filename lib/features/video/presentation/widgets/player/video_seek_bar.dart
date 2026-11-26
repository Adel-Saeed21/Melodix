import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';

/// Elapsed time, a seek slider and the length. While dragging, the slider
/// follows the finger (the player isn't asked to seek on every pixel);
/// the seek happens on release.
class VideoSeekBar extends StatefulWidget {
  const VideoSeekBar({
    super.key,
    required this.engine,
    required this.onSeek,
    this.onDragging,
  });

  final VideoEngine engine;
  final ValueChanged<Duration> onSeek;

  /// True while a finger is on the slider (to keep the controls shown).
  final ValueChanged<bool>? onDragging;

  @override
  State<VideoSeekBar> createState() => _VideoSeekBarState();
}

class _VideoSeekBarState extends State<VideoSeekBar> {
  double? _dragMs;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final timeStyle = TextStyle(
      color: Colors.white,
      fontSize: AppTextSizes.xs,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // Its own layer: the ticking time never repaints the video or buttons.
    return RepaintBoundary(
      child: ValueListenableBuilder<VideoEngineValue>(
        valueListenable: widget.engine,
        builder: (context, value, _) {
          final totalMs = value.duration.inMilliseconds.toDouble();
          final max = totalMs > 0 ? totalMs : 1.0;
          final currentMs = (_dragMs ?? value.position.inMilliseconds)
              .toDouble()
              .clamp(0.0, max);
          final buffered = value.bufferedTo.inMilliseconds.clamp(0, max) / max;
          return Row(
            children: [
              SizedBox(
                width: 52.w,
                child: Text(
                  formatDuration(Duration(milliseconds: currentMs.round())),
                  textAlign: TextAlign.center,
                  style: timeStyle,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    activeTrackColor: primary,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
                    secondaryActiveTrackColor: Colors.white.withValues(
                      alpha: 0.45,
                    ),
                    thumbColor: primary,
                    overlayColor: primary.withValues(alpha: 0.2),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                  ),
                  child: Slider(
                    max: max,
                    value: currentMs,
                    secondaryTrackValue: buffered * max,
                    onChangeStart: (v) {
                      widget.onDragging?.call(true);
                      setState(() => _dragMs = v);
                    },
                    onChanged: (v) => setState(() => _dragMs = v),
                    onChangeEnd: (v) {
                      widget.onSeek(Duration(milliseconds: v.round()));
                      widget.onDragging?.call(false);
                      setState(() => _dragMs = null);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 52.w,
                child: Text(
                  formatDuration(value.duration),
                  textAlign: TextAlign.center,
                  style: timeStyle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
