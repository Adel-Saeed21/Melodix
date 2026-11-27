import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/entities/playback_error.dart';

/// A queue chosen (a tap, or a restored session) but not loaded yet: what
/// the app shows meanwhile is the chosen song, right away (never the
/// previous song's index).
class PendingQueue {
  const PendingQueue(
    this.request,
    this.songs,
    this.title,
    this.index,
    this.position,
  );

  /// Which queue request this is (a newer tap replaces it).
  final int request;
  final List<Song> songs;
  final String? title;
  final int index;

  /// Where it starts (a restored session's saved position).
  final Duration position;

  Song get song => songs[index];

  /// What to show while it loads.
  NowPlaying toNowPlaying({
    required bool isPlaying,
    required PlaybackRepeat repeat,
    required bool shuffle,
    required PlaybackError? error,
    required int errorSequence,
  }) {
    // The tapped song starts the order when shuffling.
    final position = shuffle ? 0 : index;
    final count = songs.length;
    return NowPlaying(
      queue: songs,
      queueTitle: title,
      currentIndex: index,
      isPlaying: isPlaying,
      isLoading: true,
      duration: song.duration,
      repeatMode: repeat,
      shuffle: shuffle,
      hasNext: repeat != PlaybackRepeat.off || position < count - 1,
      hasPrevious: repeat != PlaybackRepeat.off || position > 0,
      error: error,
      errorSequence: errorSequence,
    );
  }
}
