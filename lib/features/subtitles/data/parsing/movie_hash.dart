import 'dart:io';
import 'dart:typed_data';

/// OpenSubtitles' fingerprint of a video file: its size plus the 64-bit
/// little-endian words of its first and last 64 KB, summed (wrapping), as
/// 16 hex digits. Subtitles found by it were made for this exact file, so
/// their timing fits.
///
/// Null for files under 128 KB or that can't be read.
Future<String?> openSubtitlesHash(File file) async {
  const chunk = 64 * 1024;
  RandomAccessFile? raf;
  try {
    raf = await file.open();
    final size = await raf.length();
    if (size < chunk * 2) return null;
    final head = await raf.read(chunk);
    await raf.setPosition(size - chunk);
    final tail = await raf.read(chunk);
    return movieHashOf(size, head, tail);
  } on FileSystemException {
    return null;
  } finally {
    await raf?.close();
  }
}

/// The hash from the file's [size] and its first and last 64 KB.
String movieHashOf(int size, Uint8List head, Uint8List tail) {
  final mask = (BigInt.one << 64) - BigInt.one;
  var hash = BigInt.from(size);
  for (final part in [head, tail]) {
    final data = ByteData.sublistView(part);
    for (var i = 0; i + 8 <= data.lengthInBytes; i += 8) {
      final low = data.getUint32(i, Endian.little);
      final high = data.getUint32(i + 4, Endian.little);
      hash = (hash + (BigInt.from(high) << 32) + BigInt.from(low)) & mask;
    }
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
