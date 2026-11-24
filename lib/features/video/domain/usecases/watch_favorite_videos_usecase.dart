import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/repositories/video_library_repository.dart';

/// The favourite videos, newest first, kept up to date.
class WatchFavoriteVideosUseCase {
  const WatchFavoriteVideosUseCase(this.repository);

  final VideoLibraryRepository repository;

  Stream<List<Video>> call() => repository.watchFavoriteVideos();
}
