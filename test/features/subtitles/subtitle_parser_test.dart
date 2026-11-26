import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/subtitles/data/parsing/movie_hash.dart';
import 'package:melodix/features/subtitles/data/parsing/subtitle_parser.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_cue.dart';

void main() {
  const parser = SubtitleParser();

  Duration ms(int value) => Duration(milliseconds: value);

  group('SRT', () {
    test('cues with their times and text', () {
      final timeline = parser.parse('''
1
00:00:01,000 --> 00:00:04,500
Hello there.

2
00:01:02,250 --> 00:01:05,000
Two
lines
''');
      expect(timeline.cues, [
        SubtitleCue(start: ms(1000), end: ms(4500), text: 'Hello there.'),
        SubtitleCue(start: ms(62250), end: ms(65000), text: 'Two\nlines'),
      ]);
    });

    test('Windows line ends, a BOM, and extra blank lines', () {
      final timeline = parser.parse(
        '﻿1\r\n00:00:01,000 --> 00:00:02,000\r\nHi\r\n\r\n\r\n\r\n'
        '2\r\n00:00:03,000 --> 00:00:04,000\r\nBye\r\n',
      );
      expect(timeline.cues.map((c) => c.text), ['Hi', 'Bye']);
    });

    test('formatting is removed and entities decoded', () {
      final timeline = parser.parse('''
1
00:00:01,000 --> 00:00:02,000
{\\an8}<i>Tom &amp; Jerry</i> <font color="red">&lt;3</font>
''');
      expect(timeline.cues.single.text, 'Tom & Jerry <3');
    });

    test('broken blocks are skipped, the rest kept', () {
      final timeline = parser.parse('''
1
00:00:01,000 --> 00:00:02,000
Good

2
not a time --> at all
Bad

3
00:00:05,000 --> 00:00:04,000
Ends before it starts

4
00:00:06,000 --> 00:00:07,000

5
00:00:08,000 --> 00:00:09,000
Also good
''');
      expect(timeline.cues.map((c) => c.text), ['Good', 'Also good']);
    });

    test('out of order cues are sorted', () {
      final timeline = parser.parse('''
2
00:00:05,000 --> 00:00:06,000
Second

1
00:00:01,000 --> 00:00:02,000
First
''');
      expect(timeline.cues.map((c) => c.text), ['First', 'Second']);
    });
  });

  group('WebVTT', () {
    test('header, NOTE, STYLE, cue ids and settings are handled', () {
      final timeline = parser.parse('''
WEBVTT - A title
Kind: captions

NOTE This is a comment
spanning lines

STYLE
::cue { color: yellow }

intro
00:01.000 --> 00:04.000 line:90% align:center
<v Roger>Short times, <c.yellow>a voice</c>

00:00:05.5 --> 00:00:06.25
Fraction digits
''');
      expect(timeline.cues, [
        SubtitleCue(
          start: ms(1000),
          end: ms(4000),
          text: 'Short times, a voice',
        ),
        SubtitleCue(start: ms(5500), end: ms(6250), text: 'Fraction digits'),
      ]);
    });
  });

  group('unreadable files', () {
    test('no captions at all is an error', () {
      expect(
        () => parser.parse('just some text\nwith no times'),
        throwsA(isA<SubtitleFormatException>()),
      );
      expect(() => parser.parse(''), throwsA(isA<SubtitleFormatException>()));
      expect(
        () => parser.parse('WEBVTT\n\nNOTE nothing here\n'),
        throwsA(isA<SubtitleFormatException>()),
      );
    });

    test('a huge file is refused', () {
      expect(
        () => parser.parseBytes(Uint8List(SubtitleParser.maxBytes + 1)),
        throwsA(isA<SubtitleFormatException>()),
      );
    });

    test('invalid times', () {
      expect(SubtitleParser.parseTime('00:61:00,000'), isNull);
      expect(SubtitleParser.parseTime('1:02'), isNull);
      expect(SubtitleParser.parseTime('01:02:03,4'), ms(3723400));
    });
  });

  group('text encodings', () {
    const srt = '1\n00:00:01,000 --> 00:00:02,000\nCafé\n';

    test('UTF-8, with or without its marker', () {
      final bytes = utf8.encode(srt);
      expect(parser.parseBytes(bytes).cues.single.text, 'Café');
      expect(
        parser
            .parseBytes(Uint8List.fromList([0xEF, 0xBB, 0xBF, ...bytes]))
            .cues
            .single
            .text,
        'Café',
      );
    });

    test('UTF-16 (little and big endian)', () {
      final le = <int>[0xFF, 0xFE];
      final be = <int>[0xFE, 0xFF];
      for (final unit in srt.codeUnits) {
        le.addAll([unit & 0xFF, unit >> 8]);
        be.addAll([unit >> 8, unit & 0xFF]);
      }
      expect(
        parser.parseBytes(Uint8List.fromList(le)).cues.single.text,
        'Café',
      );
      expect(
        parser.parseBytes(Uint8List.fromList(be)).cues.single.text,
        'Café',
      );
    });

    test('an old single-byte file is read, not rejected', () {
      final bytes = Uint8List.fromList(latin1.encode(srt));
      expect(parser.parseBytes(bytes).cues.single.text, 'Café');
    });
  });

  group('timeline', () {
    final timeline = SubtitleTimeline([
      SubtitleCue(start: ms(1000), end: ms(3000), text: 'A'),
      SubtitleCue(start: ms(2000), end: ms(4000), text: 'B'),
      SubtitleCue(start: ms(6000), end: ms(7000), text: 'C'),
    ]);

    test('the text at a position, overlaps one per line', () {
      expect(timeline.textAt(Duration.zero), isNull);
      expect(timeline.textAt(ms(1000)), 'A');
      expect(timeline.textAt(ms(2500)), 'A\nB');
      expect(timeline.textAt(ms(3000)), 'B'); // A ends (exclusive)
      expect(timeline.textAt(ms(5000)), isNull); // a gap
      expect(timeline.textAt(ms(6999)), 'C');
      expect(timeline.textAt(ms(7000)), isNull);
    });

    test('empty', () {
      expect(SubtitleTimeline.empty.textAt(ms(1)), isNull);
    });
  });

  group('file fingerprint (OpenSubtitles hash)', () {
    test('size plus the 64-bit words of the first and last 64 KB', () {
      final chunk = Uint8List(64 * 1024);
      expect(movieHashOf(131072, chunk, chunk), '0000000000020000');
    });

    test('wraps at 64 bits', () {
      final ones = Uint8List(64 * 1024)..fillRange(0, 64 * 1024, 0xFF);
      // Each word is 2^64 - 1, i.e. -1: 16384 of them.
      expect(
        movieHashOf(131072, ones, ones),
        (131072 - 16384).toRadixString(16).padLeft(16, '0'),
      );
    });
  });
}
