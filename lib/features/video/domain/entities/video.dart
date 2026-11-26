import 'package:equatable/equatable.dart';

/// A video in the device's library, with what the user did with it.
class Video extends Equatable {
  const Video({
    required this.id,
    required this.title,
    required this.duration,
    required this.width,
    required this.height,
    required this.createdAt,
    required this.isFavorite,
    required this.playCount,
    required this.lastPosition,
    this.lastPlayedAt,
  });

  /// The media library's id for it.
  final String id;
  final String title;
  final Duration duration;
  final int width;
  final int height;
  final DateTime createdAt;
  final bool isFavorite;
  final int playCount;

  /// Where playback stopped ("continue watching"); zero: from the start.
  final Duration lastPosition;

  /// When it was last watched; null: never.
  final DateTime? lastPlayedAt;

  /// Started but not finished: can be resumed.
  bool get canResume => lastPosition > Duration.zero && lastPosition < duration;

  /// How much was watched (0–1), for progress bars.
  double get watchedFraction => duration > Duration.zero
      ? (lastPosition.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
      : 0;

  Video copyWith({
    bool? isFavorite,
    Duration? lastPosition,
    DateTime? lastPlayedAt,
    int? playCount,
  }) => Video(
    id: id,
    title: title,
    duration: duration,
    width: width,
    height: height,
    createdAt: createdAt,
    isFavorite: isFavorite ?? this.isFavorite,
    playCount: playCount ?? this.playCount,
    lastPosition: lastPosition ?? this.lastPosition,
    lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    duration,
    width,
    height,
    createdAt,
    isFavorite,
    playCount,
    lastPosition,
    lastPlayedAt,
  ];
}
