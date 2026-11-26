import 'package:equatable/equatable.dart';

class PlaybackProgress extends Equatable {
  const PlaybackProgress({
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  static const zero = PlaybackProgress();

  final Duration position;
  final Duration duration;
  Duration get remaining {
    final left = duration - position;
    return left.isNegative ? Duration.zero : left;
  }

  double get fraction {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [position, duration];
}
