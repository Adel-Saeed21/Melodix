import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Soft glowing orbs in the accent colour (and a hue next to it), drifting
/// slowly (behind the onboarding and Now Playing). [progress] (e.g.
/// the onboarding's page, 0..n) shifts them a little, for depth.
class GlowBackground extends StatelessWidget {
  const GlowBackground({super.key, required this.time, required this.progress});

  /// 0–1, looping.
  final Animation<double> time;
  final ValueListenable<double> progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final second = HSLColor.fromColor(accent)
        .withHue((HSLColor.fromColor(accent).hue + 45) % 360)
        .toColor();
    final dark = theme.brightness == Brightness.dark;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _OrbsPainter(
          time: time,
          progress: progress,
          base: theme.colorScheme.surface,
          accent: accent,
          second: second,
          strength: dark ? 0.32 : 0.22,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _OrbsPainter extends CustomPainter {
  _OrbsPainter({
    required this.time,
    required this.progress,
    required this.base,
    required this.accent,
    required this.second,
    required this.strength,
  }) : super(repaint: Listenable.merge([time, progress]));

  final Animation<double> time;
  final ValueListenable<double> progress;
  final Color base;
  final Color accent;
  final Color second;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final t = time.value * 2 * math.pi;
    final shift = progress.value * size.width * 0.08;
    void orb(Offset c, double r, Color color, double alpha) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    final w = size.width;
    final h = size.height;
    orb(
      Offset(w * 0.15 + math.sin(t) * w * 0.08 - shift, h * 0.18),
      w * 0.75,
      accent,
      strength,
    );
    orb(
      Offset(w * 0.95 + math.cos(t) * w * 0.06 - shift * 0.5, h * 0.55),
      w * 0.65,
      second,
      strength * 0.8,
    );
    orb(
      Offset(w * 0.3 + math.cos(t + 1) * w * 0.05, h * 0.98),
      w * 0.6,
      accent,
      strength * 0.6,
    );
  }

  @override
  bool shouldRepaint(_OrbsPainter old) =>
      old.base != base || old.accent != accent || old.strength != strength;
}
