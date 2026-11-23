import 'package:material_ui/material_ui.dart';

/// A small widget that counts how often it gets painted. Put it next to an
/// animating widget: if the animation's repaints spread, this count grows.
class PaintCounter extends StatelessWidget {
  const PaintCounter({super.key, required this.counter});

  final PaintCount counter;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(10, 10), painter: _CountingPainter(counter));
}

class PaintCount {
  int value = 0;
}

class _CountingPainter extends CustomPainter {
  _CountingPainter(this.counter);

  final PaintCount counter;

  @override
  void paint(Canvas canvas, Size size) => counter.value++;

  @override
  bool shouldRepaint(_CountingPainter oldDelegate) => false;
}
