import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';

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
  test('comparing player states never walks a 2,000-song queue', () {
    // The player keeps the same list while the queue doesn't change, so
    // equality stops at "same list" instead of comparing every song.
    final queue = [for (var i = 0; i < 2000; i++) CountingSong(i)];
    final previous = NowPlaying(queue: queue, currentIndex: 0);
    CountingSong.reads = 0;

    for (var i = 0; i < 50; i++) {
      final next = NowPlaying(queue: queue, currentIndex: 0);
      expect(previous == next, isTrue);
    }

    expect(CountingSong.reads, 0);
  });

  test('the playback position is not part of the player state', () {
    // Position ticks travel on their own stream (PlaybackProgress), so
    // nothing that follows NowPlaying can be woken up by one.
    final props = NowPlaying(queue: [playerSong(1)], currentIndex: 0).props;
    expect(props.whereType<Duration>(), [Duration.zero]); // the song length
  });

  test('a new queue is detected', () {
    final first = [playerSong(1), playerSong(2)];
    final second = [playerSong(3)];
    final a = NowPlaying(queue: first, currentIndex: 0);
    final b = NowPlaying(queue: second, currentIndex: 0);

    expect(a == b, isFalse);
  });

  test('song, play state, modes, next/previous, title and errors count', () {
    final queue = [playerSong(1), playerSong(2)];
    final base = NowPlaying(queue: queue, currentIndex: 0);
    final changes = [
      NowPlaying(queue: queue, currentIndex: 1),
      NowPlaying(queue: queue, currentIndex: 0, isPlaying: true),
      NowPlaying(queue: queue, currentIndex: 0, isLoading: true),
      NowPlaying(queue: queue, currentIndex: 0, isCompleted: true),
      NowPlaying(queue: queue, currentIndex: 0, repeatMode: PlaybackRepeat.one),
      NowPlaying(queue: queue, currentIndex: 0, shuffle: true),
      NowPlaying(queue: queue, currentIndex: 0, hasNext: true),
      NowPlaying(queue: queue, currentIndex: 0, hasPrevious: true),
      NowPlaying(queue: queue, currentIndex: 0, queueTitle: 'Gym'),
      NowPlaying(queue: queue, currentIndex: 0, errorSequence: 1),
      NowPlaying(
        queue: queue,
        currentIndex: 0,
        duration: const Duration(minutes: 3),
      ),
    ];
    for (final changed in changes) {
      expect(base == changed, isFalse, reason: '$changed');
    }
  });
}
