import 'dart:convert';
import 'dart:typed_data';

import 'package:melodix/features/subtitles/domain/entities/subtitle_cue.dart';

/// The file isn't SRT or WebVTT, or holds no readable caption.
class SubtitleFormatException implements Exception {
  const SubtitleFormatException(this.message);
  final String message;

  @override
  String toString() => 'SubtitleFormatException($message)';
}

/// Reads SRT and WebVTT files.
///
/// Forgiving, like video players are: a broken block is skipped, not the
/// whole file. Only a file with no readable caption at all is an error.
///
/// * Both formats' times: `01:02:03,456` (SRT), `01:02:03.456` and
///   `02:03.456` (WebVTT); 1–3 decimal digits.
/// * WebVTT headers, NOTE / STYLE / REGION blocks, cue ids and cue
///   settings (`line:90%`) are ignored.
/// * Formatting (`<i>`, `<font>`, `<c.yellow>`, `{\an8}`) is removed; the
///   common HTML entities are decoded.
class SubtitleParser {
  const SubtitleParser();

  /// Files larger than this aren't subtitles.
  static const int maxBytes = 5 * 1024 * 1024;

  static final RegExp _blankLines = RegExp(r'\n[ \t]*\n');
  static final RegExp _timing = RegExp(r'^\s*(\S+)\s*-->\s*(\S+)');
  static final RegExp _time = RegExp(
    r'^(?:(\d+):)?(\d{1,2}):(\d{1,2})[,.](\d{1,3})$',
  );
  static final RegExp _tags = RegExp(r'<[^>]*>|\{\\[^}]*\}');

  /// Parses a file's bytes (any common text encoding).
  SubtitleTimeline parseBytes(Uint8List bytes) {
    if (bytes.length > maxBytes) {
      throw const SubtitleFormatException('too large');
    }
    return parse(decodeSubtitleText(bytes));
  }

  SubtitleTimeline parse(String content) {
    final text = content
        .replaceFirst('﻿', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final cues = <SubtitleCue>[];
    for (final block in text.split(_blankLines)) {
      final cue = _cue(block);
      if (cue != null) cues.add(cue);
    }
    if (cues.isEmpty) {
      throw const SubtitleFormatException('no captions');
    }
    return SubtitleTimeline(cues);
  }

  SubtitleCue? _cue(String block) {
    final lines = block.split('\n');
    final first = lines.indexWhere((l) => l.trim().isNotEmpty);
    if (first < 0) return null;
    final head = lines[first].trimLeft();
    if (head.startsWith('NOTE') ||
        head.startsWith('STYLE') ||
        head.startsWith('REGION')) {
      return null;
    }
    // The timing line is the first or second (after a number / cue id).
    final at = lines.indexWhere((l) => l.contains('-->'));
    if (at < 0 || at > first + 1) return null;
    final match = _timing.firstMatch(lines[at]);
    if (match == null) return null;
    final start = parseTime(match.group(1)!);
    final end = parseTime(match.group(2)!);
    if (start == null || end == null || end <= start) return null;

    final body = lines
        .skip(at + 1)
        .map(_clean)
        .where((l) => l.isNotEmpty)
        .join('\n');
    if (body.isEmpty) return null;
    return SubtitleCue(start: start, end: end, text: body);
  }

  /// "01:02:03,456", "01:02:03.456" or "02:03.4" (null if not a time).
  static Duration? parseTime(String value) {
    final m = _time.firstMatch(value.trim());
    if (m == null) return null;
    final hours = int.parse(m.group(1) ?? '0');
    final minutes = int.parse(m.group(2)!);
    final seconds = int.parse(m.group(3)!);
    if (minutes > 59 || seconds > 59) return null;
    final fraction = m.group(4)!.padRight(3, '0');
    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: int.parse(fraction),
    );
  }

  static String _clean(String line) => line
      .replaceAll(_tags, '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&lrm;', '')
      .replaceAll('&rlm;', '')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&')
      .trim();
}

/// A subtitle file's text: UTF-8 (the usual), UTF-16 with its marker, and
/// older files in a single-byte encoding (read as Latin-1 / Windows-1252
/// rather than failing).
String decodeSubtitleText(Uint8List bytes) {
  if (bytes.length >= 2) {
    if (bytes[0] == 0xFF && bytes[1] == 0xFE) return _utf16(bytes, 2, true);
    if (bytes[0] == 0xFE && bytes[1] == 0xFF) return _utf16(bytes, 2, false);
  }
  final start =
      bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF
      ? 3
      : 0;
  final body = Uint8List.sublistView(bytes, start);
  try {
    return utf8.decode(body);
  } on FormatException {
    return latin1.decode(body);
  }
}

String _utf16(Uint8List bytes, int start, bool littleEndian) {
  final data = ByteData.sublistView(bytes, start);
  final units = <int>[
    for (var i = 0; i + 1 < data.lengthInBytes; i += 2)
      data.getUint16(i, littleEndian ? Endian.little : Endian.big),
  ];
  return String.fromCharCodes(units);
}
