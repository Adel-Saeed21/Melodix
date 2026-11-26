import 'package:material_ui/material_ui.dart';

/// The Melodix mark (the five rounded bars of
/// `assets/vectors/melodix_logo.svg`), drawn in code in any [color].
///
/// [levels] (0–1 per bar, 5 values) scales each bar from its baseline, so
/// the mark can move like an equalizer; null draws the logo as it is.
class MelodixMark extends StatelessWidget {
  const MelodixMark({
    super.key,
    required this.size,
    required this.color,
    this.levels,
  });

  /// The mark's width (its height is about two thirds of that).
  final double size;
  final Color color;
  final List<double>? levels;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * _height / _width),
      painter: _MarkPainter(color, levels),
    );
  }
}

/// (x, top, height) in the logo's 1000-unit space; each bar 96 wide.
const List<(double, double, double)> _bars = [
  (172, 280, 440),
  (312, 420, 300),
  (452, 530, 190),
  (592, 420, 300),
  (732, 280, 440),
];
const double _left = 172;
const double _baseline = 720;
const double _barWidth = 96;
const double _width = 828 - 172;
const double _height = 720 - 280;

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color, this.levels);

  final Color color;
  final List<double>? levels;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _width;
    final paint = Paint()..color = color;
    for (var i = 0; i < _bars.length; i++) {
      final (x, _, height) = _bars[i];
      final level = levels == null ? 1.0 : levels![i].clamp(0.12, 1.0);
      // Moving bars range up to the tallest bar's height.
      final h = (levels == null ? height : _height * level) * scale;
      final rect = Rect.fromLTWH(
        (x - _left) * scale,
        (_baseline - 280) * scale - h,
        _barWidth * scale,
        h,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(_barWidth / 2 * scale)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.color != color || old.levels != levels;
}
