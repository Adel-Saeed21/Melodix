import 'package:melodix/features/video/domain/entities/video_progress.dart';

/// How much of each video was watched.
abstract interface class VideoProgressRepository {
  /// Every played video's progress, by video id, now and on every change.
  Stream<Map<String, VideoProgress>> watchProgress();

  /// One video's progress; null if it was never played (or can't be read).
  Future<VideoProgress?> progress(String videoId);

  /// Counts a play and stamps when it happened. Never throws (a lost
  /// count must not interrupt the video).
  Future<void> recordPlay(String videoId);

  /// Remembers where playback of a [length]-long video stopped, to resume
  /// there; a finished video ([VideoProgress.isFinished]) is saved as "from
  /// the start". Never throws.
  Future<void> savePosition(
    String videoId,
    Duration position, {
    required Duration length,
  });
}
