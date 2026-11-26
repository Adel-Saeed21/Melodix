import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/repositories/video_repository.dart';

/// The favourite videos, newest first, kept up to date.
class WatchFavoriteVideosUseCase {
  const WatchFavoriteVideosUseCase(this.repository);

  final VideoRepository repository;

  Stream<List<Video>> call() => repository.watchFavoriteVideos();
}
