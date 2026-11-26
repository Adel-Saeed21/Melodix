import 'package:melodix/features/video/domain/entities/video_progress.dart';
import 'package:melodix/features/video/domain/repositories/video_progress_repository.dart';

/// Every played video's progress, by video id, kept up to date.
class WatchVideoProgressUseCase {
  const WatchVideoProgressUseCase(this.repository);

  final VideoProgressRepository repository;

  Stream<Map<String, VideoProgress>> call() => repository.watchProgress();
}

/// One video's progress (where to resume it); null if never played.
class GetVideoProgressUseCase {
  const GetVideoProgressUseCase(this.repository);

  final VideoProgressRepository repository;

  Future<VideoProgress?> call(String videoId) => repository.progress(videoId);
}

/// Counts a play of a video (for history and "most watched").
class RecordVideoPlayUseCase {
  const RecordVideoPlayUseCase(this.repository);

  final VideoProgressRepository repository;

  Future<void> call(String videoId) => repository.recordPlay(videoId);
}

/// Remembers where a video stopped, so it resumes there next time.
class SaveVideoPositionUseCase {
  const SaveVideoPositionUseCase(this.repository);

  final VideoProgressRepository repository;

  Future<void> call(
    String videoId,
    Duration position, {
    required Duration length,
  }) => repository.savePosition(videoId, position, length: length);
}
