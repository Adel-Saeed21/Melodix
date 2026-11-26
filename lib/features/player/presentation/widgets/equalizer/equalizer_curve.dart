import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/player/domain/entities/equalizer_preset.dart';

/// The sound's shape: a smooth line through the bands, filled with the
/// accent below it, a faint 0 dB line across.
class EqualizerCurve extends StatelessWidget {
  const EqualizerCurve({super.key, required this.gains});

  final List<double> gains;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _CurvePainter(
        gains: gains,
        accent: theme.primaryColor,
        ink: theme.colorScheme.onSurface,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({required this.gains, required this.accent, required this.ink});

  final List<double> gains;
  final Color accent;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    canvas.drawLine(
      Offset(0, mid),
      Offset(size.width, mid),
      Paint()
        ..color = ink.withValues(alpha: 0.12)
        ..strokeWidth = 1,
    );
    final low = math.log(equalizerBandsHz.first / 1.6);
    final high = math.log(equalizerBandsHz.last * 1.4);
    final path = Path();
    const steps = 64;
    for (var i = 0; i <= steps; i++) {
      final x = size.width * i / steps;
      final hz = math.exp(low + (high - low) * i / steps);
      final db = gainAt(hz, gains);
      final y = mid - db / equalizerMaxGainDb * (size.height / 2 - 4);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas
      ..drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withValues(alpha: 0.35),
              accent.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      )
      ..drawPath(
        path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.accent != accent || old.ink != ink || !identical(old.gains, gains);
}
