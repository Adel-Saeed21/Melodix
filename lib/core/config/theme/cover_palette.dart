import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// Picks an accent from a song's cover: the most common vivid hue, made
/// bright enough to read on both themes. Null when the cover is grey,
/// black-and-white or missing (the user's own accent is used then).
abstract final class CoverPalette {
  /// The cover is shrunk to this width first: plenty for a colour.
  static const int sampleSize = 32;

  /// Decodes [encoded] (PNG / JPEG bytes) and picks its accent.
  static Future<Color?> fromEncoded(Uint8List encoded) async {
    try {
      final codec = await ui.instantiateImageCodec(
        encoded,
        targetWidth: sampleSize,
        targetHeight: sampleSize,
      );
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      frame.image.dispose();
      codec.dispose();
      if (data == null) return null;
      return fromRgba(data.buffer.asUint8List());
    } catch (_) {
      return null; // not an image we can read: no accent from it
    }
  }

  /// [rgba]: 4 bytes per pixel. Hues are counted in 24 buckets, each
  /// pixel weighted by how vivid it is; the strongest bucket wins.
  static Color? fromRgba(Uint8List rgba) {
    const buckets = 24;
    final weight = List<double>.filled(buckets, 0);
    final hueSum = List<double>.filled(buckets, 0);
    final satSum = List<double>.filled(buckets, 0);
    var counted = 0;
    for (var i = 0; i + 3 < rgba.length; i += 4) {
      if (rgba[i + 3] < 128) continue; // transparent
      final hsl = HSLColor.fromColor(
        Color.fromARGB(255, rgba[i], rgba[i + 1], rgba[i + 2]),
      );
      counted++;
      // Greys, near-black and near-white say nothing about the cover.
      if (hsl.saturation < 0.3 ||
          hsl.lightness < 0.15 ||
          hsl.lightness > 0.85) {
        continue;
      }
      final b = (hsl.hue / 360 * buckets).floor() % buckets;
      // Mid-lightness, saturated pixels count most.
      final w = hsl.saturation * (1 - (hsl.lightness - 0.5).abs() * 1.5);
      weight[b] += w;
      hueSum[b] += hsl.hue * w;
      satSum[b] += hsl.saturation * w;
    }
    if (counted == 0) return null;
    var best = 0;
    for (var b = 1; b < buckets; b++) {
      if (weight[b] > weight[best]) best = b;
    }
    // Too little colour (a few vivid pixels in a grey cover).
    if (weight[best] < counted * 0.04) return null;
    final hue = hueSum[best] / weight[best];
    final saturation = (satSum[best] / weight[best]).clamp(0.55, 0.9);
    return HSLColor.fromAHSL(1, hue, saturation, 0.55).toColor();
  }
}
