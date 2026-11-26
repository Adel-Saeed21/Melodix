import 'package:melodix/features/lyrics/domain/entities/lyrics.dart';

/// Reads lyrics text: LRC (`[01:23.45]words`) when it has timestamps,
/// plain lines otherwise.
///
/// * Several stamps on one line (`[00:12.00][01:30.00]chorus`) repeat it.
/// * `[offset:+500]` shifts every line (ms; positive means earlier).
/// * Tag lines (`[ar:...]`, `[ti:...]`) and enhanced word stamps
///   (`<00:12.30>`) are dropped.
/// * Returns null when there's nothing to show.
class LrcParser {
  const LrcParser();

  static final RegExp _stamp = RegExp(
    r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]',
  );
  static final RegExp _offset = RegExp(
    r'^\[offset:\s*([+-]?\d+)\]',
    caseSensitive: false,
  );
  static final RegExp _tag = RegExp(r'^\[[a-zA-Z#]+:.*\]$');
  static final RegExp _wordStamp = RegExp(r'<\d{1,3}:\d{1,2}(?:[.:]\d{1,3})?>');

  Lyrics? parse(String text, LyricsSource source) {
    final rawLines = text
        .replaceFirst('﻿', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    var offset = Duration.zero;
    final timed = <LyricLine>[];
    final plain = <String>[];
    for (final raw in rawLines) {
      final line = raw.trim();
      final shift = _offset.firstMatch(line);
      if (shift != null) {
        offset = Duration(milliseconds: int.parse(shift.group(1)!));
        continue;
      }
      final stamps = _stamp.allMatches(line).toList();
      if (stamps.isEmpty || stamps.first.start != 0) {
        if (_tag.hasMatch(line)) continue;
        plain.add(line);
        continue;
      }
      final words = line
          .substring(stamps.last.end)
          .replaceAll(_wordStamp, '')
          .trim();
      for (final m in stamps) {
        final minutes = int.parse(m.group(1)!);
        final seconds = int.parse(m.group(2)!);
        final fraction = m.group(3) ?? '0';
        final ms = int.parse(fraction.padRight(3, '0').substring(0, 3));
        final at =
            Duration(minutes: minutes, seconds: seconds, milliseconds: ms) -
            offset;
        timed.add(
          LyricLine(words, time: at < Duration.zero ? Duration.zero : at),
        );
      }
    }
    if (timed.any((l) => l.text.isNotEmpty)) {
      timed.sort((a, b) => a.time!.compareTo(b.time!));
      return Lyrics(lines: List.unmodifiable(timed), source: source);
    }
    // Plain: trimmed of blank lines at the ends.
    while (plain.isNotEmpty && plain.first.isEmpty) {
      plain.removeAt(0);
    }
    while (plain.isNotEmpty && plain.last.isEmpty) {
      plain.removeLast();
    }
    if (plain.isEmpty) return null;
    return Lyrics(
      lines: List.unmodifiable([for (final l in plain) LyricLine(l)]),
      source: source,
    );
  }
}
