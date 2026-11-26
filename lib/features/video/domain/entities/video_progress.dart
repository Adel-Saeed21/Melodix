import 'package:equatable/equatable.dart';

/// How much of a video was watched.
class VideoProgress extends Equatable {
  const VideoProgress({
    required this.videoId,
    required this.position,
    this.lastPlayedAt,
    this.playCount = 0,
  });

  /// Within this distance of the end, a video counts as watched: it isn't
  /// resumed (it starts over) and leaves "continue watching". The one rule,
  /// for the player, the saved progress and the lists.
  static const Duration finishedWithin = Duration(seconds: 10);

  static bool isFinished(Duration position, Duration length) =>
      length - position <= finishedWithin;

  final String videoId;

  /// Where playback stopped; zero: from the start.
  final Duration position;
  final DateTime? lastPlayedAt;
  final int playCount;

  /// Started but not finished: playing it again resumes at [position].
  bool canResume(Duration length) =>
      position > Duration.zero && !isFinished(position, length);

  /// How much was watched (0–1), for progress bars.
  double fraction(Duration length) => length > Duration.zero
      ? (position.inMilliseconds / length.inMilliseconds).clamp(0.0, 1.0)
      : 0;

  @override
  List<Object?> get props => [videoId, position, lastPlayedAt, playCount];
}
