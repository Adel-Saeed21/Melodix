import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_state_changes.dart';

import 'player_fixtures.dart';

/// A song that counts how often its equality fields are read.
class CountingSong extends Song {
  CountingSong(int id)
    : super(
        id: id,
        title: 'Song $id',
        artist: 'A',
        album: 'B',
        albumId: 1,
        duration: const Duration(minutes: 3),
        path: '/m/$id.mp3',
        playbackUri: Uri.parse('content://x/$id'),
        isFavorite: false,
        playCount: 0,
      );

  static int reads = 0;

  @override
  List<Object?> get props {
    reads++;
    return super.props;
  }
}

void main() {
  test('position ticks never compare the songs in the queue', () {
    final queue = [for (var i = 0; i < 2000; i++) CountingSong(i)];
    var previous = NowPlaying(queue: queue, currentIndex: 0);
    CountingSong.reads = 0;

    for (var tick = 1; tick <= 50; tick++) {
      final next = NowPlaying(
        queue: queue, // the player keeps the same list between ticks
        currentIndex: 0,
        position: Duration(seconds: tick),
      );
      expect(previous == next, isFalse); // position changed → new state
      expect(changedBesidesProgress(previous, next), isFalse);
      previous = next;
    }

    expect(CountingSong.reads, 0);
  });

  test('a new queue is detected', () {
    final first = [playerSong(1), playerSong(2)];
    final second = [playerSong(3)];
    final a = NowPlaying(queue: first, currentIndex: 0);
    final b = NowPlaying(queue: second, currentIndex: 0);

    expect(a == b, isFalse);
    expect(changedBesidesProgress(a, b), isTrue);
  });

  test('replacing the queue with a new list counts as a change', () {
    // e.g. the same songs played again from another list: the UI refreshes.
    final songs = [playerSong(1), playerSong(2)];
    final a = NowPlaying(queue: songs, currentIndex: 0);
    final b = NowPlaying(queue: [...songs], currentIndex: 0);

    expect(changedBesidesProgress(a, b), isTrue);
  });

  test('song, play state, repeat, shuffle and next/previous changes count', () {
    final queue = [playerSong(1), playerSong(2)];
    final base = NowPlaying(queue: queue, currentIndex: 0);
    final changes = [
      NowPlaying(queue: queue, currentIndex: 1),
      NowPlaying(queue: queue, currentIndex: 0, isPlaying: true),
      NowPlaying(queue: queue, currentIndex: 0, repeatMode: PlaybackRepeat.one),
      NowPlaying(queue: queue, currentIndex: 0, shuffle: true),
      NowPlaying(queue: queue, currentIndex: 0, hasNext: true),
      NowPlaying(queue: queue, currentIndex: 0, hasPrevious: true),
      NowPlaying(queue: queue, currentIndex: 0, queueTitle: 'Gym'),
      NowPlaying(queue: queue, currentIndex: 0, errorSequence: 1),
    ];
    for (final changed in changes) {
      expect(changedBesidesProgress(base, changed), isTrue);
    }
  });
}
