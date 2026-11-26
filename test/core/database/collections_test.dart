import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/database/collections/recent_music_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/collections/video_collection.dart';
import 'package:melodix/core/database/fast_hash.dart';
import 'package:melodix/core/models/local_song.dart';
import 'package:melodix/core/models/local_video.dart';

const _song = LocalSong(
  id: 42,
  title: 'Track',
  artist: 'Artist',
  album: 'Album',
  albumId: 7,
  duration: Duration(minutes: 3),
  path: '/music/track.mp3',
  uri: 'content://media/external/audio/media/42',
  size: 2048,
);

final _video = LocalVideo(
  id: 'abc-123',
  title: 'Clip',
  duration: const Duration(seconds: 90),
  width: 1920,
  height: 1080,
  createdAt: DateTime(2026, 1, 2),
);

void main() {
  group('fastHash', () {
    test('is stable and distinguishes ids', () {
      expect(fastHash('abc-123'), fastHash('abc-123'));
      expect(fastHash('abc-123'), isNot(fastHash('abc-124')));
    });
  });

  group('SongCollection', () {
    test('uses the MediaStore id and round-trips to LocalSong', () {
      final row = SongCollection.fromLocalSong(_song);

      expect(row.id, 42);
      expect(row.durationMs, 180000);
      expect(row.isFavorite, isFalse);
      expect(row.playCount, 0);
      expect(row.toLocalSong(), _song);
    });

    test('keeps user data from the previous row on re-scan', () {
      final previous = SongCollection.fromLocalSong(_song)
        ..isFavorite = true
        ..playCount = 5
        ..addedAt = DateTime(2026, 1, 1);

      final updated = SongCollection.fromLocalSong(_song, previous: previous);

      expect(updated.isFavorite, isTrue);
      expect(updated.playCount, 5);
      expect(updated.addedAt, DateTime(2026, 1, 1));
    });
  });

  group('VideoCollection', () {
    test('derives a stable Isar id from the asset id', () {
      final row = VideoCollection.fromLocalVideo(_video);

      expect(row.id, fastHash('abc-123'));
      expect(row.toLocalVideo(), _video);
    });

    test('keeps the favourite flag on re-scan', () {
      final previous = VideoCollection.fromLocalVideo(_video)
        ..isFavorite = true;

      final updated = VideoCollection.fromLocalVideo(
        _video,
        previous: previous,
      );

      expect(updated.isFavorite, isTrue);
    });
  });

  group('RecentMusicCollection', () {
    test('uses the song id so replays update one entry', () {
      final at = DateTime(2026, 3, 4, 10);
      final entry = RecentMusicCollection.played(42, at: at);

      expect(entry.id, 42);
      expect(entry.songId, 42);
      expect(entry.playedAt, at);
    });
  });
}
