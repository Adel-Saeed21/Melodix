import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/stats/domain/entities/song_listening.dart';
import 'package:melodix/features/stats/domain/listening_stats.dart';

SongListening _song(
  int id, {
  String artist = 'A',
  int plays = 0,
  int listenedSeconds = 0,
  bool favourite = false,
  bool inLibrary = true,
}) => SongListening(
  id: id,
  title: 'Song $id',
  artist: artist,
  playCount: plays,
  listened: Duration(seconds: listenedSeconds),
  isFavorite: favourite,
  inLibrary: inLibrary,
);

void main() {
  test('time is what was really heard, not plays × length', () {
    final stats = ListeningStats.of([
      // 10 plays, but most were stopped early: 12 min really heard.
      _song(1, artist: 'Ana', plays: 10, listenedSeconds: 720),
      _song(2, artist: 'Ben', plays: 4, listenedSeconds: 600),
      _song(3, artist: 'Ben', plays: 8, listenedSeconds: 1200),
      _song(4, artist: unknownArtist, plays: 30, listenedSeconds: 60),
      // Heard for a while, never long enough for a play.
      _song(5, listenedSeconds: 25),
    ]);
    expect(stats.listened, const Duration(seconds: 2605));
    expect(stats.plays, 52);
    expect([for (final s in stats.topSongs) s.id], [4, 1, 3, 2]);
    // An unknown artist isn't an artist.
    expect(stats.topArtists, [
      (artist: 'Ben', plays: 12),
      (artist: 'Ana', plays: 10),
    ]);
  });

  test('removed songs count in the history, not in the library', () {
    final stats = ListeningStats.of([
      _song(1, plays: 2, listenedSeconds: 300, favourite: true),
      _song(2, plays: 9, listenedSeconds: 900, inLibrary: false),
    ]);
    expect(stats.plays, 11);
    expect(stats.listened, const Duration(seconds: 1200));
    expect(stats.topSongs.first.id, 2, reason: 'still a top song');
    expect(stats.songCount, 1);
    expect(stats.favourites, 1);
  });

  test('nothing heard yet', () {
    final stats = ListeningStats.of([_song(1)]);
    expect(stats.isEmpty, isTrue);
    expect(stats.topSongs, isEmpty);
  });

  test('heard, but no play yet: not empty (the time shows)', () {
    final stats = ListeningStats.of([_song(1, listenedSeconds: 20)]);
    expect(stats.isEmpty, isFalse);
    expect(stats.plays, 0);
  });
}
