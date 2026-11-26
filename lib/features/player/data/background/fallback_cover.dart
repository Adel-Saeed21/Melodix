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

  // The mark at 56% of the cover's width, centred.
  _drawMark(
    canvas,
    center: ui.Offset(s / 2, s / 2),
    width: s * 0.56,
    paint: ui.Paint()..color = const ui.Color(0xF2FFFFFF),
  );

  final image = await recorder.endRecording().toImage(size, size);
  try {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return png!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// [cover] with the Melodix finish, for the lock screen and the media
/// notification: the picture fills the square; a green wash rises from the
/// bottom-right corner; the Melodix mark sits in a green badge on the right.
///
/// Android 13+ paints its whole player from the cover (and crops it to a
/// wide card, keeping the middle band), so the green tints the player and
/// the badge stays in view. PNG bytes, [size] pixels square. Throws if
/// [cover] isn't an image (the caller then uses it as it is).
Future<Uint8List> renderBrandedCover(Uint8List cover, {int size = 512}) async {
  final codec = await ui.instantiateImageCodec(cover);
  final ui.Image picture;
  try {
    picture = (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
  final s = size.toDouble();
  final area = ui.Rect.fromLTWH(0, 0, s, s);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, area);

  // The picture, filling the square (centre crop).
  final w = picture.width.toDouble();
  final h = picture.height.toDouble();
  final side = w < h ? w : h;
  canvas.drawImageRect(
    picture,
    ui.Rect.fromLTWH((w - side) / 2, (h - side) / 2, side, side),
    area,
    ui.Paint()..filterQuality = ui.FilterQuality.medium,
  );
  picture.dispose();

  // The green wash from the bottom-right corner.
  canvas.drawRect(
    area,
    ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(s, s),
        ui.Offset(s * 0.3, s * 0.3),
        [
          AppColors.primaryColor.withValues(alpha: 0.72),
          AppColors.primaryColor.withValues(alpha: 0),
        ],
      ),
  );
  // A thin green line along the right edge: on brand even when cropped.
  canvas.drawRect(
    ui.Rect.fromLTWH(s * 0.985, 0, s * 0.015, s),
    ui.Paint()..color = AppColors.primaryColor,
  );

  // The badge: a green disc with a white ring and the white mark, on the
  // right, inside the band a wide card keeps.
  final center = ui.Offset(s * 0.84, s * 0.62);
  final radius = s * 0.1;
  canvas
    ..drawCircle(
      center,
      radius * 1.08,
      ui.Paint()..color = const ui.Color(0x55000000),
    )
    ..drawCircle(center, radius, ui.Paint()..color = AppColors.primaryColor)
    ..drawCircle(
      center,
      radius,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = s * 0.008
        ..color = const ui.Color(0xE6FFFFFF),
    );
  _drawMark(
    canvas,
    center: center,
    width: radius * 1.2,
    paint: ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );

  final image = await recorder.endRecording().toImage(size, size);
  try {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return png!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// The Melodix mark (the logo's five bars, in its own 1000-unit
/// coordinates: x 172–828, y 280–720, sharing a baseline), [width] wide
/// and centred on [center].
void _drawMark(
  ui.Canvas canvas, {
  required ui.Offset center,
  required double width,
  required ui.Paint paint,
}) {
  final scale = width / _logoWidth;
  final left = center.dx - _logoWidth * scale / 2 - _logoLeft * scale;
  final top = center.dy - _logoHeight * scale / 2 - _logoTop * scale;
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
      paint,
    );
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
