import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/player/data/background/fallback_cover.dart';

/// A stand-in album cover: blue at the top, red at the bottom.
Future<Uint8List> sampleCover(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final area = ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  ui.Canvas(recorder, area).drawRect(
    area,
    ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset.zero,
        ui.Offset(0, height.toDouble()),
        const [ui.Color(0xFF2040C0), ui.Color(0xFFC02040)],
      ),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png!.buffer.asUint8List();
}

Future<ui.Color Function(int, int)> pixels(Uint8List png, int size) async {
  final codec = await ui.instantiateImageCodec(png);
  final image = (await codec.getNextFrame()).image;
  expect(image.width, size);
  expect(image.height, size);
  final data = (await image.toByteData())!;
  image.dispose();
  return (x, y) {
    final i = (y * size + x) * 4;
    return ui.Color.fromARGB(
      data.getUint8(i + 3),
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
  };
}

int c(double channel) => (channel * 255).round();

void main() {
  testWidgets('the cover, with the green wash and the Melodix badge', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // Wide (a video still): centre-cropped to a square.
      final png = await renderBrandedCover(
        await sampleCover(640, 360),
        size: 256,
      );
      final preview = Platform.environment['BRANDED_COVER_PREVIEW'];
      if (preview != null) await File(preview).writeAsBytes(png);
      final at = await pixels(png, 256);

      // Top left: the picture itself (blue), untouched by the wash.
      final picture = at(10, 10);
      expect(c(picture.b), greaterThan(c(picture.g)));
      // Bottom right: the wash makes it green.
      final corner = at(240, 250);
      expect(c(corner.g), greaterThan(c(corner.b)));
      // The badge (centre 0.84, 0.62; radius 0.1): green disc...
      final disc = at((256 * 0.84 - 256 * 0.08).round(), (256 * 0.62).round());
      expect(c(disc.g), greaterThan(150));
      expect(c(disc.g), greaterThan(c(disc.r)));
      // ...with the white mark in the middle (the middle bar).
      final mark = at((256 * 0.84).round(), (256 * 0.62 + 256 * 0.02).round());
      expect(c(mark.r), greaterThan(235));
      expect(c(mark.b), greaterThan(235));
    });
  });

  testWidgets('not an image: an error (the caller keeps the original)', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await expectLater(
        renderBrandedCover(Uint8List.fromList([1, 2, 3])),
        throwsA(anything),
      );
    });
  });
}
