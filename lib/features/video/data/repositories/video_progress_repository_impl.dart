import 'package:melodix/core/database/video_local_storage.dart';
import 'package:melodix/features/video/data/mappers/video_mapper.dart';
import 'package:melodix/features/video/data/repositories/video_errors.dart';
import 'package:melodix/features/video/domain/entities/video_progress.dart';
import 'package:melodix/features/video/domain/repositories/video_progress_repository.dart';

class VideoProgressRepositoryImpl implements VideoProgressRepository {
  const VideoProgressRepositoryImpl(this._storage);

  final VideoLocalStorage _storage;

  @override
  Stream<Map<String, VideoProgress>> watchProgress() =>
      _storage.watchProgress().map(VideoMapper.toProgressMap);

  @override
  Future<VideoProgress?> progress(String videoId) async {
    try {
      final row = await _storage.getProgress(videoId);
      return row == null ? null : VideoMapper.toProgress(row);
    } catch (e, stack) {
      logVideoProblem('Could not read where a video stopped', e, stack);
      return null; // it just starts from the beginning
    }
  }

  @override
  Future<void> recordPlay(String videoId) async {
    try {
      await _storage.recordPlay(videoId);
    } catch (e, stack) {
      logVideoProblem('Could not count a video play', e, stack);
    }
  }

  @override
  Future<void> savePosition(
    String videoId,
    Duration position, {
    required Duration length,
  }) async {
    try {
      await _storage.savePlaybackPosition(
        videoId,
        VideoProgress.isFinished(position, length) ? Duration.zero : position,
      );
    } catch (e, stack) {
      logVideoProblem('Could not save where a video stopped', e, stack);
    }
  }
}
