import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/repositories/video_library_repository.dart';

/// All videos, newest first, kept up to date.
class WatchVideosUseCase {
  const WatchVideosUseCase(this.repository);

  final VideoLibraryRepository repository;

  Stream<List<Video>> call() => repository.watchVideos();
}
