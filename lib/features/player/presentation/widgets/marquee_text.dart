import 'package:material_ui/material_ui.dart';

import 'package:melodix/features/player/presentation/utils/player_rebuild_stats.dart';

/// Single-line text that scrolls horizontally in a loop when it doesn't fit
/// (pausing briefly at the start of each loop). Short text just sits still.
/// With "remove animations" enabled, long text is cut with "…" instead.
class MarqueeText extends StatefulWidget {
  const MarqueeText(
    this.text, {
    super.key,
    this.style,
    this.gap = 48,
    this.velocity = 32,
    this.pause = const Duration(milliseconds: 1500),
  });

  final String text;
  final TextStyle? style;

  /// Space between the end of the text and its next copy.
  final double gap;

  /// Scroll speed in logical pixels per second.
  final double velocity;

  /// Still time at the start of each loop, so the start is readable.
  final Duration pause;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  /// Distance scrolled per loop (text width + gap); 0 when it fits.
  double _travel = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _configure(double travel) {
    if (travel == _travel) return;
    _travel = travel;
    if (travel <= 0) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    final scrollMs = travel / widget.velocity * 1000;
    _controller
      ..duration = Duration(
        milliseconds: widget.pause.inMilliseconds + scrollMs.round(),
      )
      ..repeat();
  }

  /// Offset at the current point of the loop: still, then scrolling.
  double get _offset {
    final total = _controller.duration?.inMilliseconds ?? 0;
    if (total == 0 || _travel <= 0) return 0;
    final pauseFraction = widget.pause.inMilliseconds / total;
    final t = _controller.value;
    if (t <= pauseFraction) return 0;
    return (t - pauseFraction) / (1 - pauseFraction) * _travel;
  }

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _travel = -1; // force re-measure, restart from the beginning
      _controller.value = 0;
    }
  }

  // Cached text size. Measuring lays out the text, so it's only redone when
  // what affects the size changes, not on every rebuild.
  Size? _measured;
  Object? _measuredFor;

  Size _measure(TextStyle style, TextScaler scaler, TextDirection direction) {
    final key = (widget.text, style, scaler, direction);
    final cached = _measured;
    if (cached != null && key == _measuredFor) return cached;
    // ignore: invalid_use_of_visible_for_testing_member
    PlayerRebuildStats.hit('marqueeMeasure');
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      maxLines: 1,
      textDirection: direction,
      textScaler: scaler,
    )..layout();
    final size = painter.size;
    painter.dispose();
    _measuredFor = key;
    return _measured = size;
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _measure(
          style,
          MediaQuery.textScalerOf(context),
          Directionality.of(context),
        );
        final textWidth = size.width;
        final fits = textWidth <= constraints.maxWidth;
        final reduceMotion = MediaQuery.disableAnimationsOf(context);

        if (fits || reduceMotion) {
          _configure(0);
          return Text(
            widget.text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          );
        }
        _configure(textWidth + widget.gap);

        final line = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.text, style: style, maxLines: 1, softWrap: false),
            SizedBox(width: widget.gap),
            Text(widget.text, style: style, maxLines: 1, softWrap: false),
          ],
        );
        // Scrolls every frame. Flow moves the text while painting (no
        // rebuild, no relayout of the page), and the boundary keeps those
        // repaints off its neighbours.
        return RepaintBoundary(
          child: SizedBox(
            width: constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : textWidth,
            height: size.height,
            child: Flow(
              delegate: _MarqueeFlowDelegate(
                animation: _controller,
                offset: () => _offset,
              ),
              children: [line],
            ),
          ),
        );
      },
    );
  }
}

/// Paints the scrolling line at the current offset, repainting on every
/// animation tick without rebuilding or relaying out anything.
class _MarqueeFlowDelegate extends FlowDelegate {
  _MarqueeFlowDelegate({
    required Animation<double> animation,
    required this.offset,
  }) : super(repaint: animation);

  final double Function() offset;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      // The line is wider than the box on purpose (it scrolls).
      BoxConstraints(maxHeight: constraints.maxHeight);

  @override
  void paintChildren(FlowPaintingContext context) {
    context.paintChild(
      0,
      transform: Matrix4.translationValues(-offset(), 0, 0),
    );
  }

  @override
  bool shouldRepaint(_MarqueeFlowDelegate oldDelegate) => true;
}
