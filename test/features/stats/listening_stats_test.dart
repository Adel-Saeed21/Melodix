import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/service/local_song_builder.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/stats/domain/listening_stats.dart';

Song _song(
  int id, {
  String artist = 'A',
  int plays = 0,
  bool favourite = false,
}) => Song(
  id: id,
  title: 'Song $id',
  artist: artist,
  album: 'Album',
  albumId: 1,
  duration: const Duration(minutes: 3),
  path: '/m/$id.mp3',
  playbackUri: Uri.parse('content://x/$id'),
  isFavorite: favourite,
  playCount: plays,
);

void main() {
  test('time, plays, top songs and artists from the play counts', () {
    final stats = ListeningStats.of([
      _song(1, artist: 'Ana', plays: 10, favourite: true),
      _song(2, artist: 'Ben', plays: 4),
      _song(3, artist: 'Ben', plays: 8),
      _song(4, artist: unknownArtist, plays: 30),
      _song(5),
    ]);
    expect(stats.plays, 52);
    expect(stats.listened, const Duration(minutes: 156));
    expect(stats.songCount, 5);
    expect(stats.favourites, 1);
    expect([for (final s in stats.topSongs) s.id], [4, 1, 3, 2]);
    // An unknown artist isn't an artist.
    expect(
      stats.topArtists,
      [(artist: 'Ana', plays: 10), (artist: 'Ben', plays: 12)].reversed,
    );
  });

  test('nothing played yet', () {
    final stats = ListeningStats.of([_song(1)]);
    expect(stats.isEmpty, isTrue);
    expect(stats.topSongs, isEmpty);
  });
}
