import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Drives the splash logo's effects, so the widget only draws them.
///
/// Timeline (1.5 s intro): the halo fades in, one sheen sweeps across the
/// logo, and the wordmark rises in. After the intro the halo keeps
/// "breathing" until [dispose]. The logo itself is never animated, so it
/// matches the native splash from the first frame.
///
/// Create it with the widget's [TickerProvider], call [start] once
/// [MediaQuery] is available, and [dispose] with the widget.
class SplashLogoAnimationService {
  SplashLogoAnimationService({
    required TickerProvider vsync,
    Duration introDuration = const Duration(milliseconds: 1500),
    Duration breathDuration = const Duration(milliseconds: 2400),
  }) : _intro = AnimationController(vsync: vsync, duration: introDuration),
       _breath = AnimationController(vsync: vsync, duration: breathDuration) {
    _halo = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _sheen = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.25, 0.85, curve: Curves.easeInOut),
    );
    _wordmark = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
    );
  }

  final AnimationController _intro;
  final AnimationController _breath;
  late final Animation<double> _halo;
  late final Animation<double> _sheen;
  late final Animation<double> _wordmark;

  bool _started = false;
  bool _disposed = false;

  // Listenables for AnimatedBuilder.

  /// Changes whenever the halo's opacity or scale changes.
  Listenable get haloListenable => Listenable.merge([_halo, _breath]);
  Listenable get sheenListenable => _sheen;
  Listenable get wordmarkListenable => _wordmark;

  // Current values.

  double get _breathValue => Curves.easeInOut.transform(_breath.value);

  /// 0 → fully transparent. Breathes between 75% and 100% after the intro.
  double get haloOpacity => _halo.value * (0.75 + 0.25 * _breathValue);

  /// Grows from 0.9 to 1.0 during the intro, then pulses up to +5%.
  double get haloScale => 0.9 + 0.1 * _halo.value + 0.05 * _breathValue;

  /// 0 before the sweep starts, 1 after it ends.
  double get sheenProgress => _sheen.value;

  /// True only while the sheen is crossing the logo.
  bool get isSheenActive => sheenProgress > 0 && sheenProgress < 1;

  double get wordmarkOpacity => _wordmark.value;

  /// Vertical offset in logical pixels: starts 10 px low, ends at 0.
  double get wordmarkOffsetY => 10 * (1 - _wordmark.value);

  /// Starts the effects once. With [reduceMotion] (the system "remove
  /// animations" setting) it jumps straight to the final state instead.
  void start({required bool reduceMotion}) {
    if (_started || _disposed) return;
    _started = true;
    if (reduceMotion) {
      _intro.value = 1;
      _breath.value = 0.5;
      return;
    }
    _intro.forward().whenComplete(() {
      if (!_disposed) _breath.repeat(reverse: true);
    });
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _intro.dispose();
    _breath.dispose();
  }

  /// A soft white band crossing the logo diagonally at [progress] (0..1).
  static LinearGradient sheenGradient(double progress) {
    final center = -0.3 + 1.6 * progress;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      transform: const GradientRotation(math.pi / 12),
      colors: [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0.32),
        Colors.white.withValues(alpha: 0),
      ],
      stops: [
        (center - 0.18).clamp(0.0, 1.0),
        center.clamp(0.0, 1.0),
        (center + 0.18).clamp(0.0, 1.0),
      ],
    );
  }
}
