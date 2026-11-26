import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/features/player/data/background/fallback_cover.dart';

void main() {
  testWidgets('a square PNG: the white Melodix bars on the app green', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final png = await renderFallbackCover(size: 256);
      final preview = Platform.environment['FALLBACK_COVER_PREVIEW'];
      if (preview != null) await File(preview).writeAsBytes(png);

      final codec = await ui.instantiateImageCodec(png);
      final image = (await codec.getNextFrame()).image;
      expect(image.width, 256);
      expect(image.height, 256);

      final pixels = (await image.toByteData())!;
      ui.Color at(int x, int y) {
        final i = (y * 256 + x) * 4;
        return ui.Color.fromARGB(
          pixels.getUint8(i + 3),
          pixels.getUint8(i),
          pixels.getUint8(i + 1),
          pixels.getUint8(i + 2),
        );
      }

      // Top-left corner: close to the app's green (under a soft highlight).
      final corner = at(2, 2);
      expect((corner.g * 255).round(), greaterThan(180));
      expect(corner.g, greaterThan(corner.r));
      expect(corner.g, greaterThan(corner.b));
      expect(AppColors.primaryColor.g, greaterThan(AppColors.primaryColor.r));
      // Inside the middle bar (logo x 452–548, y 530–720 of 1000): white.
      final bar = at(128, 150);
      expect((bar.r * 255).round(), greaterThan(235));
      expect((bar.b * 255).round(), greaterThan(235));
      // Between two bars, near the top: still background (green).
      final gap = at(96, 90);
      expect(gap.g, greaterThan(gap.r));
      image.dispose();
    });
  });
}
