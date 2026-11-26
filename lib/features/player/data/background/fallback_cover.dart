import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:melodix/core/config/theme/app_colors.dart';

/// The cover the lock screen and media notification show for songs without
/// their own: the Melodix mark (the five rounded bars of
/// `assets/vectors/melodix_logo.svg`) in white on the app's green.
///
/// On Android 13+ the system player paints its whole card from the cover,
/// so this keeps cover-less songs on-brand instead of a grey box. Returns
/// PNG bytes, [size] pixels square.
Future<Uint8List> renderFallbackCover({int size = 512}) async {
  final s = size.toDouble();
  final area = ui.Rect.fromLTWH(0, 0, s, s);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, area);

  // The app's green, deepening diagonally.
  canvas.drawRect(
    area,
    ui.Paint()
      ..shader = ui.Gradient.linear(ui.Offset.zero, ui.Offset(s, s), const [
        AppColors.primaryColor,
        _deepGreen,
      ]),
  );
  // Soft light from the top left, for depth.
  canvas.drawRect(
    area,
    ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(s * 0.22, s * 0.18),
        s * 0.85,
        const [ui.Color(0x2EFFFFFF), ui.Color(0x00FFFFFF)],
      ),
  );

  // The logo's bars, in its own 1000-unit coordinates: they span x 172–828
  // and y 280–720 (all ending at the same baseline). Scaled to 56% of the
  // cover's width and centred.
  final scale = s * 0.56 / _logoWidth;
  final left = (s - _logoWidth * scale) / 2 - _logoLeft * scale;
  final top = (s - _logoHeight * scale) / 2 - _logoTop * scale;
  final white = ui.Paint()..color = const ui.Color(0xF2FFFFFF);
  for (final (x, y, height) in _bars) {
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(
          left + x * scale,
          top + y * scale,
          _barWidth * scale,
          height * scale,
        ),
        ui.Radius.circular(_barWidth / 2 * scale),
      ),
      white,
    );
  }

  final image = await recorder.endRecording().toImage(size, size);
  try {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return png!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Bars of melodix_logo.svg: (x, top, height); each 96 wide, fully round.
const List<(double, double, double)> _bars = [
  (172, 280, 440),
  (312, 420, 300),
  (452, 530, 190),
  (592, 420, 300),
  (732, 280, 440),
];
const double _barWidth = 96;
const double _logoLeft = 172;
const double _logoTop = 280;
const double _logoWidth = 828 - 172;
const double _logoHeight = 720 - 280;

/// A dark green from the same hue as [AppColors.primaryColor].
const ui.Color _deepGreen = ui.Color(0xFF0F3A0D);
