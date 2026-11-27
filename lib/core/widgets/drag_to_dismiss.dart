import 'package:material_ui/material_ui.dart';

/// Lets the user pull [child] down to close it (like a sheet).
///
/// The page follows the finger, shrinking a little. Releasing past
/// [distanceThreshold] of the height, or flicking down faster than
/// [velocityThreshold], calls [onDismiss]; otherwise it springs back. Only
/// vertical drags are used, so horizontal ones (e.g. a seek bar) still work.
///
/// Cheap on every frame of the drag: the offset lives in a notifier, so
/// nothing rebuilds, and the page is only moved and scaled (a transform),
/// never faded (fading a whole page draws it again into an extra layer on
/// each frame).
class DragToDismiss extends StatefulWidget {
  const DragToDismiss({
    super.key,
    required this.child,
    required this.onDismiss,
    this.distanceThreshold = 0.25,
    this.velocityThreshold = 800,
  });

  final Widget child;
  final VoidCallback onDismiss;

  /// Fraction of the height to drag before releasing closes it.
  final double distanceThreshold;

  /// Downward fling speed (logical px/s) that closes it right away.
  final double velocityThreshold;

  @override
  State<DragToDismiss> createState() => _DragToDismissState();
}

class _DragToDismissState extends State<DragToDismiss>
    with SingleTickerProviderStateMixin {
  /// Current drag distance in logical pixels (0 = resting).
  final ValueNotifier<double> _offset = ValueNotifier(0);
  bool _dismissed = false;

  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(_onSettleTick);
  Animation<double>? _settleAnimation;

  @override
  void dispose() {
    _settle.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _onSettleTick() {
    final animation = _settleAnimation;
    if (animation != null) _offset.value = animation.value;
  }

  void _onUpdate(DragUpdateDetails details) {
    if (_dismissed) return;
    _settle.stop();
    // Only downward pulls move the page; it never goes above its resting place.
    _offset.value = (_offset.value + details.delta.dy).clamp(
      0,
      double.infinity,
    );
  }

  void _onEnd(DragEndDetails details, double height) {
    if (_dismissed) return;
    final velocity = details.primaryVelocity ?? 0;
    final offset = _offset.value;
    final farEnough = offset > height * widget.distanceThreshold;
    final fastEnough = velocity > widget.velocityThreshold;
    if (offset > 0 && (farEnough || fastEnough)) {
      _dismissed = true;
      widget.onDismiss();
      return;
    }
    // Not far enough: spring back.
    _settleAnimation = Tween(
      begin: offset,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _settle, curve: Curves.easeOutCubic));
    _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragUpdate: _onUpdate,
          onVerticalDragEnd: (details) => _onEnd(details, height),
          child: ValueListenableBuilder<double>(
            valueListenable: _offset,
            // Built once; only the transform below follows the drag.
            child: widget.child,
            builder: (context, offset, child) {
              final progress = height == 0
                  ? 0.0
                  : (offset / height).clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(0, offset),
                child: Transform.scale(
                  scale: 1 - 0.06 * progress,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
