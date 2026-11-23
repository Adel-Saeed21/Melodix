import 'package:equatable/equatable.dart';

class LocalVideo extends Equatable {
  const LocalVideo({
    required this.id,
    required this.title,
    required this.duration,
    required this.width,
    required this.height,
    required this.createdAt,
  });

  /// Media library id (photo_manager asset id).
  final String id;
  final String title;
  final Duration duration;
  final int width;
  final int height;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id];
}
