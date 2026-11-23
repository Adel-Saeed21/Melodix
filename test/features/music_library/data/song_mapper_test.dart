import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';

import '../fixtures.dart';

void main() {
  group('playbackUri', () {
    test('uses the stored content URI on Android', () {
      const mapper = SongMapper(isAndroid: true);
      final row = songRow(5, uri: 'content://media/external/audio/media/5');

      expect(
        mapper.playbackUri(row).toString(),
        'content://media/external/audio/media/5',
      );
    });

    test('rebuilds the content URI from the MediaStore id on Android', () {
      const mapper = SongMapper(isAndroid: true);

      final uri = mapper.playbackUri(songRow(77));

      expect(uri.scheme, 'content');
      expect(uri.toString(), 'content://media/external/audio/media/77');
    });

    test('falls back to the file path elsewhere', () {
      const mapper = SongMapper(isAndroid: false);

      final uri = mapper.playbackUri(songRow(3));

      expect(uri.scheme, 'file');
      expect(uri.toFilePath(), '/storage/emulated/0/Music/3.mp3');
    });
  });

  test('toEntity copies song fields and user data', () {
    const mapper = SongMapper(isAndroid: true);
    final row = songRow(9, title: 'Hello')
      ..isFavorite = true
      ..playCount = 4;

    final song = mapper.toEntity(row);

    expect(song.id, 9);
    expect(song.title, 'Hello');
    expect(song.duration, const Duration(minutes: 1));
    expect(song.isFavorite, isTrue);
    expect(song.playCount, 4);
    expect(song.playbackUri.scheme, 'content');
  });

  group('dateAdded', () {
    test('uses the device date when known', () {
      final row = songRow(1)..dateAdded = DateTime(2025, 5, 5);
      expect(
        const SongMapper(isAndroid: true).toEntity(row).dateAdded,
        DateTime(2025, 5, 5),
      );
    });

    test('falls back to when the app first saw the song', () {
      final row = songRow(1)..addedAt = DateTime(2026, 2, 2);
      expect(
        const SongMapper(isAndroid: true).toEntity(row).dateAdded,
        DateTime(2026, 2, 2),
      );
    });
  });
}
