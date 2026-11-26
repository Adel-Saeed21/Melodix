import 'package:equatable/equatable.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/player/domain/entities/playback_error.dart';

enum PlaybackRepeat { off, all, one }

class NowPlaying extends Equatable {
  const NowPlaying({
    this.queue = const [],
    this.queueTitle,
    this.currentIndex,
    this.isPlaying = false,
    this.isLoading = false,
    this.isCompleted = false,
    this.duration = Duration.zero,
    this.repeatMode = PlaybackRepeat.off,
    this.shuffle = false,
    this.hasNext = false,
    this.hasPrevious = false,
    this.error,
    this.errorSequence = 0,
  });

  static const idle = NowPlaying();

  final List<Song> queue;
  final String? queueTitle;
  final int? currentIndex;
  final bool isPlaying;
  final bool isLoading;
  final bool isCompleted;
  final Duration duration;
  final PlaybackRepeat repeatMode;
  final bool shuffle;
  final bool hasNext;
  final bool hasPrevious;
  final PlaybackError? error;
  final int errorSequence;

  Song? get currentSong {
    final index = currentIndex;
    if (index == null || index < 0 || index >= queue.length) return null;
    return queue[index];
  }

  bool get hasSong => currentSong != null;

  @override
  List<Object?> get props => [
    queue,
    queueTitle,
    currentIndex,
    isPlaying,
    isLoading,
    isCompleted,
    duration,
    repeatMode,
    shuffle,
    hasNext,
    hasPrevious,
    error,
    errorSequence,
  ];
}
