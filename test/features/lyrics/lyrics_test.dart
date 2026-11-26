import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/service/local_song_builder.dart';
import 'package:melodix/features/lyrics/data/embedded_lyrics_reader.dart';
import 'package:melodix/features/lyrics/data/lrc_parser.dart';
import 'package:melodix/features/lyrics/data/lrclib_client.dart';
import 'package:melodix/features/lyrics/data/lyrics_repository_impl.dart';
import 'package:melodix/features/lyrics/domain/entities/lyrics.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

Song _song(String path, {String title = 'Song', String artist = 'Band'}) =>
    Song(
      id: 7,
      title: title,
      artist: artist,
      album: 'Album',
      albumId: 1,
      duration: const Duration(minutes: 3),
      path: path,
      playbackUri: Uri.parse('content://x/7'),
      isFavorite: false,
      playCount: 0,
    );

/// An ID3v2.3 tag holding [frames] (id, body).
Uint8List _id3(List<(String, List<int>)> frames) {
  final body = <int>[];
  for (final (id, data) in frames) {
    final n = data.length;
    body
      ..addAll(ascii.encode(id))
      ..addAll([n >> 24 & 0xFF, n >> 16 & 0xFF, n >> 8 & 0xFF, n & 0xFF])
      ..addAll([0, 0])
      ..addAll(data);
  }
  final n = body.length;
  return Uint8List.fromList([
    ...ascii.encode('ID3'),
    3,
    0,
    0,
    // synchsafe size
    n >> 21 & 0x7F,
    n >> 14 & 0x7F,
    n >> 7 & 0x7F,
    n & 0x7F,
    ...body,
  ]);
}

class _FakeOnline extends LrclibClient {
  _FakeOnline(this.answer);

  final OnlineLyricsText? answer;
  final calls = <(String, String?)>[];

  @override
  Future<OnlineLyricsText?> find({
    required String title,
    String? artist,
    String? album,
    Duration? duration,
  }) async {
    calls.add((title, artist));
    return answer;
  }
}

void main() {
  const parser = LrcParser();

  group('LRC', () {
    test('timed lines, in order; repeated stamps; tags dropped', () {
      final lyrics = parser.parse(
        '[ar:Band]\n[ti:Song]\n'
        '[00:12.50]First line\n'
        '[00:05.00][01:00.00]Chorus\n'
        '[00:20.123]<00:20.20>Word <00:21.00>stamps\n',
        LyricsSource.file,
      )!;
      expect(lyrics.isSynced, isTrue);
      expect(
        [for (final l in lyrics.lines) l.text],
        ['Chorus', 'First line', 'Word stamps', 'Chorus'],
      );
      expect(
        lyrics.lines[1].time,
        const Duration(seconds: 12, milliseconds: 500),
      );
      expect(
        lyrics.lines[2].time,
        const Duration(seconds: 20, milliseconds: 123),
      );
    });

    test('offset moves every line earlier', () {
      final lyrics = parser.parse(
        '[offset:+500]\n[00:10.00]Hi',
        LyricsSource.file,
      )!;
      expect(lyrics.lines.single.time, const Duration(milliseconds: 9500));
    });

    test('plain text stays plain', () {
      final lyrics = parser.parse('\nOne\n\nTwo\n\n', LyricsSource.file)!;
      expect(lyrics.isSynced, isFalse);
      expect([for (final l in lyrics.lines) l.text], ['One', '', 'Two']);
      expect(lyrics.lineAt(const Duration(seconds: 5)), -1);
    });

    test('nothing to show: null', () {
      expect(parser.parse('[ar:Band]\n\n', LyricsSource.file), isNull);
    });

    test('the line being sung', () {
      final lyrics = parser.parse(
        '[00:01.00]a\n[00:05.00]b\n[00:09.00]c',
        LyricsSource.file,
      )!;
      expect(lyrics.lineAt(Duration.zero), -1);
      expect(lyrics.lineAt(const Duration(seconds: 1)), 0);
      expect(lyrics.lineAt(const Duration(seconds: 7)), 1);
      expect(lyrics.lineAt(const Duration(minutes: 9)), 2);
    });
  });

  group('lyrics inside the song file', () {
    const reader = EmbeddedLyricsReader();

    test('ID3 USLT (UTF-8), even holding LRC', () {
      final tag = _id3([
        ('TIT2', [3, ...utf8.encode('Song')]),
        (
          'USLT',
          [3, ...ascii.encode('eng'), 0, ...utf8.encode('[00:02.00]Héllo')],
        ),
      ]);
      final lyrics = reader.fromId3(tag)!;
      expect(lyrics.source, LyricsSource.embedded);
      expect(lyrics.lines.single.text, 'Héllo');
      expect(lyrics.lines.single.time, const Duration(seconds: 2));
    });

    test('ID3 USLT in UTF-16 with a description', () {
      final text = [0xFF, 0xFE]; // little-endian BOM
      for (final c in 'La la'.codeUnits) {
        text.addAll([c & 0xFF, c >> 8]);
      }
      final tag = _id3([
        ('USLT', [1, ...ascii.encode('eng'), 0xFF, 0xFE, 0, 0, ...text]),
      ]);
      expect(reader.fromId3(tag)!.lines.single.text, 'La la');
    });

    test('ID3 SYLT (synced, milliseconds) is preferred', () {
      List<int> line(String text, int ms) => [
        ...latin1.encode(text),
        0,
        ms >> 24 & 0xFF,
        ms >> 16 & 0xFF,
        ms >> 8 & 0xFF,
        ms & 0xFF,
      ];
      final tag = _id3([
        ('USLT', [0, ...ascii.encode('eng'), 0, ...latin1.encode('plain')]),
        (
          'SYLT',
          [
            0,
            ...ascii.encode('eng'),
            2,
            1,
            0,
            ...line('Two', 4000),
            ...line('One', 1500),
          ],
        ),
      ]);
      final lyrics = reader.fromId3(tag)!;
      expect(lyrics.isSynced, isTrue);
      expect([for (final l in lyrics.lines) l.text], ['One', 'Two']);
      expect(lyrics.lines.first.time, const Duration(milliseconds: 1500));
    });

    test('FLAC LYRICS comment, read from a file', () async {
      final dir = await Directory.systemTemp.createTemp('lyrics');
      addTearDown(() => dir.delete(recursive: true));
      List<int> le(int n) => [
        n & 0xFF,
        n >> 8 & 0xFF,
        n >> 16 & 0xFF,
        n >> 24 & 0xFF,
      ];
      final vendor = utf8.encode('test');
      final comment = utf8.encode('LYRICS=[00:03.00]Flac line');
      final block = [
        ...le(vendor.length),
        ...vendor,
        ...le(1),
        ...le(comment.length),
        ...comment,
      ];
      final file = File('${dir.path}/song.flac')
        ..writeAsBytesSync([
          ...ascii.encode('fLaC'),
          0, 0, 0, 2, 0, 0, // STREAMINFO-ish block of 2 bytes (not last)
          0x84,
          block.length >> 16 & 0xFF,
          block.length >> 8 & 0xFF,
          block.length & 0xFF,
          ...block,
        ]);
      final lyrics = (await reader.read(file.path))!;
      expect(lyrics.lines.single.text, 'Flac line');
    });

    test('a missing or unreadable file: none', () async {
      expect(await reader.read('/nope/song.mp3'), isNull);
    });
  });

  group('repository', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('lyrics'));
    tearDown(() => dir.delete(recursive: true));

    test('an .lrc beside the song', () async {
      File('${dir.path}/Song.lrc').writeAsStringSync('[00:01.00]Beside');
      final repo = LyricsRepositoryImpl(
        savedDirectory: () async => dir,
        online: _FakeOnline(null),
      );
      final lyrics = (await repo.local(_song('${dir.path}/Song.mp3')))!;
      expect(lyrics.source, LyricsSource.file);
      expect(lyrics.lines.single.text, 'Beside');
    });

    test('online: found, saved, then shown offline; removable', () async {
      final online = _FakeOnline((synced: '[00:04.00]Online', plain: 'Online'));
      final repo = LyricsRepositoryImpl(
        savedDirectory: () async => dir,
        online: online,
      );
      final song = _song('${dir.path}/Song.mp3');
      expect(await repo.local(song), isNull);
      final found = (await repo.searchOnline(song)).getOrElse(() => null)!;
      expect(found.isSynced, isTrue);
      expect(online.calls.single, ('Song', 'Band'));

      final saved = (await repo.local(song))!;
      expect(saved.source, LyricsSource.online);
      await repo.forgetSaved(song.id);
      expect(await repo.local(song), isNull);
    });

    test('a missing artist tag is taken from "Artist - Title"', () {
      expect(
        LyricsRepositoryImpl.searchTermsFor(
          _song(
            '/x.mp3',
            title: 'Queen - Bohemian Rhapsody',
            artist: unknownArtist,
          ),
        ),
        ('Bohemian Rhapsody', 'Queen'),
      );
    });
  });
}
