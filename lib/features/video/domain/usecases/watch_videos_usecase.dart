import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/repositories/video_repository.dart';

/// All videos, newest first, kept up to date.
class WatchVideosUseCase {
  const WatchVideosUseCase(this.repository);

  final VideoRepository repository;

  Stream<List<Video>> call() => repository.watchVideos();
}
