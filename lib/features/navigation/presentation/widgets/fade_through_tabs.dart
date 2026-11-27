import 'package:material_ui/material_ui.dart';

/// The tab pages, one shown at a time, like an [IndexedStack] (each keeps
/// its state while hidden), but switching with a fade-through: the old
/// page fades out quickly, then the new one fades in while sliding a
/// little from the side of the tab that was tapped (mirrored right to
/// left).
///
/// Only the two pages involved are drawn during the switch; at rest the
/// others are offstage, with their animations paused.
class FadeThroughTabs extends StatefulWidget {
  const FadeThroughTabs({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 320),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  /// How far the new page slides in, as a fraction of its width.
  static const double slide = 0.05;

  @override
  State<FadeThroughTabs> createState() => _FadeThroughTabsState();
}

class _FadeThroughTabsState extends State<FadeThroughTabs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  )..addStatusListener(_onStatus);

  /// The page leaving, while the switch runs.
  int? _previous;

  /// 1: moving to a tab further along; -1: back.
  int _direction = 1;

  /// Built once (the same objects each build, so nothing re-subscribes).
  late final Animation<double> _fadeOut = ReverseAnimation(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.35, curve: Curves.easeIn),
    ),
  );
  late final Animation<double> _fadeIn = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 1, curve: Curves.easeOut),
  );
  late final Animation<double> _slideIn = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  static const Animation<double> _shown = AlwaysStoppedAnimation(1);
  static const Animation<Offset> _still = AlwaysStoppedAnimation(Offset.zero);

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _previous != null) {
      setState(() => _previous = null);
    }
  }

  @override
  void didUpdateWidget(FadeThroughTabs old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _previous = old.index;
      _direction = widget.index > old.index ? 1 : -1;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final from = FadeThroughTabs.slide * _direction * (rtl ? -1 : 1);
    final slideIn = Tween<Offset>(
      begin: Offset(from, 0),
      end: Offset.zero,
    ).animate(_slideIn);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++) _page(i, slideIn),
      ],
    );
  }

  /// The same widgets around each page whatever its part (so a page never
  /// loses its state); only their settings change.
  Widget _page(int i, Animation<Offset> slideIn) {
    final current = i == widget.index;
    final leaving = i == _previous;
    final switching = _previous != null;
    return Offstage(
      key: ValueKey(i),
      offstage: !current && !leaving,
      child: TickerMode(
        enabled: current,
        child: IgnorePointer(
          ignoring: leaving,
          child: ExcludeSemantics(
            excluding: leaving,
            child: FadeTransition(
              opacity: !switching
                  ? _shown
                  : leaving
                  ? _fadeOut
                  : _fadeIn,
              child: SlideTransition(
                position: switching && current ? slideIn : _still,
                child: widget.children[i],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
