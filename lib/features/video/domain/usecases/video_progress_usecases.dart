import 'package:melodix/features/video/domain/repositories/video_library_repository.dart';

/// Counts a play of a video (for history and "most watched").
class RecordVideoPlayUseCase {
  const RecordVideoPlayUseCase(this.repository);

  final VideoLibraryRepository repository;

  Future<void> call(String videoId) => repository.recordPlay(videoId);
}

/// Remembers where a video stopped, so it resumes there next time.
class SaveVideoPositionUseCase {
  const SaveVideoPositionUseCase(this.repository);

  final VideoLibraryRepository repository;

  Future<void> call(String videoId, Duration position) =>
      repository.savePosition(videoId, position);
}
