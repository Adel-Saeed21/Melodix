import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:melodix/features/lyrics/data/lrc_parser.dart';
import 'package:melodix/features/lyrics/domain/entities/lyrics.dart';

/// Reads lyrics written inside an audio file's tags:
/// * MP3 (ID3v2.3 / 2.4): synced `SYLT` (milliseconds) first, then the
///   plain `USLT` (which may itself hold LRC text);
/// * FLAC: the `LYRICS`, `SYNCEDLYRICS` or `UNSYNCEDLYRICS` comment.
///
/// Only the tag at the start of the file is read, never the audio.
class EmbeddedLyricsReader {
  const EmbeddedLyricsReader({this.parser = const LrcParser()});

  final LrcParser parser;

  /// Tags larger than this (huge cover pictures) aren't read.
  static const int maxTagBytes = 16 * 1024 * 1024;

  Future<Lyrics?> read(String path) async {
    RandomAccessFile? file;
    try {
      file = await File(path).open();
      final head = await file.read(10);
      if (head.length < 10) return null;
      if (head[0] == 0x49 && head[1] == 0x44 && head[2] == 0x33) {
        final size = _synchsafe(head, 6);
        if (size <= 0 || size > maxTagBytes) return null;
        final body = await file.read(size);
        return fromId3(Uint8List.fromList([...head, ...body]));
      }
      if (head[0] == 0x66 &&
          head[1] == 0x4C &&
          head[2] == 0x61 &&
          head[3] == 0x43) {
        await file.setPosition(4);
        return await _fromFlac(file);
      }
      return null;
    } catch (_) {
      return null; // unreadable here (permissions, odd file): no lyrics
    } finally {
      await file?.close();
    }
  }

  /// Lyrics from a whole ID3v2 tag (header included).
  Lyrics? fromId3(Uint8List tag) {
    if (tag.length < 10) return null;
    final major = tag[3];
    if (major != 3 && major != 4) return null;
    final flags = tag[5];
    var data = Uint8List.sublistView(
      tag,
      10,
      (10 + _synchsafe(tag, 6)).clamp(10, tag.length),
    );
    if (flags & 0x80 != 0 && major == 3) data = _deUnsync(data);
    var pos = 0;
    if (flags & 0x40 != 0 && data.length >= 4) {
      final ext = major == 4 ? _synchsafe(data, 0) : _int32(data, 0) + 4;
      pos = ext;
    }
    String? plain;
    Lyrics? synced;
    while (pos + 10 <= data.length) {
      final id = String.fromCharCodes(data, pos, pos + 4);
      if (id.codeUnits.every((c) => c == 0)) break; // padding
      final size = major == 4
          ? _synchsafe(data, pos + 4)
          : _int32(data, pos + 4);
      final start = pos + 10;
      final end = start + size;
      if (size <= 0 || end > data.length) break;
      final frame = Uint8List.sublistView(data, start, end);
      if (id == 'SYLT') synced ??= _sylt(frame);
      if (id == 'USLT') plain ??= _uslt(frame);
      pos = end;
    }
    if (synced != null) return synced;
    if (plain == null) return null;
    return parser.parse(plain, LyricsSource.embedded);
  }

  String? _uslt(Uint8List frame) {
    if (frame.length < 5) return null;
    final encoding = frame[0];
    // language (3 bytes), then a description, then the lyrics.
    final afterDescription = _skipString(frame, 4, encoding);
    if (afterDescription == null) return null;
    final text = _decode(
      Uint8List.sublistView(frame, afterDescription),
      encoding,
    );
    return text.trim().isEmpty ? null : text;
  }

  Lyrics? _sylt(Uint8List frame) {
    if (frame.length < 7) return null;
    final encoding = frame[0];
    final format = frame[4]; // 2: milliseconds (1 is MPEG frames: unsupported)
    if (format != 2) return null;
    var pos = _skipString(frame, 6, encoding);
    if (pos == null) return null;
    final lines = <LyricLine>[];
    while (pos! < frame.length) {
      final textEnd = _terminator(frame, pos, encoding);
      if (textEnd == null) break;
      final text = _decode(
        Uint8List.sublistView(frame, pos, textEnd),
        encoding,
      );
      final stampAt = textEnd + _terminatorLength(encoding);
      if (stampAt + 4 > frame.length) break;
      final ms = _int32(frame, stampAt);
      lines.add(
        LyricLine(
          text.replaceAll('\n', ' ').trim(),
          time: Duration(milliseconds: ms),
        ),
      );
      pos = stampAt + 4;
    }
    if (!lines.any((l) => l.text.isNotEmpty)) return null;
    lines.sort((a, b) => a.time!.compareTo(b.time!));
    return Lyrics(
      lines: List.unmodifiable(lines),
      source: LyricsSource.embedded,
    );
  }

  Future<Lyrics?> _fromFlac(RandomAccessFile file) async {
    var read = 0;
    while (read < maxTagBytes) {
      final header = await file.read(4);
      if (header.length < 4) return null;
      final last = header[0] & 0x80 != 0;
      final type = header[0] & 0x7F;
      final length = (header[1] << 16) | (header[2] << 8) | header[3];
      read += 4 + length;
      if (type == 4) {
        final block = await file.read(length);
        return _vorbisComment(Uint8List.fromList(block));
      }
      if (last) return null;
      await file.setPosition(await file.position() + length);
    }
    return null;
  }

  Lyrics? _vorbisComment(Uint8List block) {
    final view = ByteData.sublistView(block);
    if (block.length < 8) return null;
    var pos = 4 + view.getUint32(0, Endian.little); // vendor
    if (pos + 4 > block.length) return null;
    final count = view.getUint32(pos, Endian.little);
    pos += 4;
    final found = <String, String>{};
    for (var i = 0; i < count && pos + 4 <= block.length; i++) {
      final length = view.getUint32(pos, Endian.little);
      pos += 4;
      if (pos + length > block.length) break;
      final entry = utf8.decode(
        Uint8List.sublistView(block, pos, pos + length),
        allowMalformed: true,
      );
      pos += length;
      final eq = entry.indexOf('=');
      if (eq <= 0) continue;
      found[entry.substring(0, eq).toUpperCase()] = entry.substring(eq + 1);
    }
    for (final key in const ['SYNCEDLYRICS', 'LYRICS', 'UNSYNCEDLYRICS']) {
      final text = found[key];
      if (text == null || text.trim().isEmpty) continue;
      final lyrics = parser.parse(text, LyricsSource.embedded);
      if (lyrics != null) return lyrics;
    }
    return null;
  }

  // Bytes and strings

  static int _synchsafe(List<int> b, int at) =>
      (b[at] & 0x7F) << 21 |
      (b[at + 1] & 0x7F) << 14 |
      (b[at + 2] & 0x7F) << 7 |
      (b[at + 3] & 0x7F);

  static int _int32(List<int> b, int at) =>
      b[at] << 24 | b[at + 1] << 16 | b[at + 2] << 8 | b[at + 3];

  /// Undoes ID3 "unsynchronisation" (0xFF 0x00 → 0xFF).
  static Uint8List _deUnsync(Uint8List data) {
    final out = BytesBuilder(copy: false);
    for (var i = 0; i < data.length; i++) {
      out.addByte(data[i]);
      if (data[i] == 0xFF && i + 1 < data.length && data[i + 1] == 0) i++;
    }
    return out.toBytes();
  }

  static int _terminatorLength(int encoding) =>
      encoding == 1 || encoding == 2 ? 2 : 1;

  /// Where the string starting at [from] ends (its terminator), or null.
  static int? _terminator(Uint8List b, int from, int encoding) {
    if (_terminatorLength(encoding) == 1) {
      for (var i = from; i < b.length; i++) {
        if (b[i] == 0) return i;
      }
      return null;
    }
    for (var i = from; i + 1 < b.length; i += 2) {
      if (b[i] == 0 && b[i + 1] == 0) return i;
    }
    return null;
  }

  /// Past the terminated string at [from].
  static int? _skipString(Uint8List b, int from, int encoding) {
    final end = _terminator(b, from, encoding);
    return end == null ? null : end + _terminatorLength(encoding);
  }

  static String _decode(Uint8List b, int encoding) {
    switch (encoding) {
      case 0:
        return latin1.decode(b);
      case 3:
        return utf8.decode(b, allowMalformed: true);
      case 1:
      case 2:
        var bigEndian = encoding == 2;
        var start = 0;
        if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xFE) {
          bigEndian = false;
          start = 2;
        } else if (b.length >= 2 && b[0] == 0xFE && b[1] == 0xFF) {
          bigEndian = true;
          start = 2;
        }
        final units = <int>[];
        for (var i = start; i + 1 < b.length; i += 2) {
          units.add(bigEndian ? b[i] << 8 | b[i + 1] : b[i + 1] << 8 | b[i]);
        }
        return String.fromCharCodes(units).replaceAll('\u0000', '');
      default:
        return '';
    }
  }
}
