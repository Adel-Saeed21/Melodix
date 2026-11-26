import 'package:equatable/equatable.dart';

/// A video in the device's library, and whether it's a favourite. (How
/// much of it was watched is a [VideoProgress], kept apart: it changes
/// every few seconds while the video plays.)
class Video extends Equatable {
  const Video({
    required this.id,
    required this.title,
    required this.duration,
    required this.width,
    required this.height,
    required this.createdAt,
    required this.isFavorite,
  });

  /// The media library's id for it.
  final String id;
  final String title;
  final Duration duration;
  final int width;
  final int height;
  final DateTime createdAt;
  final bool isFavorite;

  @override
  List<Object?> get props => [
    id,
    title,
    duration,
    width,
    height,
    createdAt,
    isFavorite,
  ];
}
