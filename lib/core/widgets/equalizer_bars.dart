import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Three bouncing bars that mark the song that's playing. When [animate] is
/// false (paused) or the system asks for less motion, the bars hold still.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({
    super.key,
    required this.animate,
    required this.color,
    this.size = 18,
  });

  final bool animate;
  final Color color;
  final double size;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Still heights (fractions of [EqualizerBars.size]) when not animating.
  static const _restHeights = [0.45, 0.85, 0.6];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final shouldAnimate =
        widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _height(int bar) {
    if (!_controller.isAnimating) return _restHeights[bar];
    // Each bar bounces on its own phase so they don't move together.
    final phase = _controller.value * 2 * math.pi + bar * 2.1;
    return 0.3 + 0.7 * (0.5 + 0.5 * math.sin(phase));
  }

  @override
  Widget build(BuildContext context) {
    final barWidth = widget.size / 5;
    // Animates every frame: its own layer keeps that off the song row.
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var bar = 0; bar < 3; bar++)
                Container(
                  width: barWidth,
                  height: widget.size * _height(bar),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(barWidth / 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
