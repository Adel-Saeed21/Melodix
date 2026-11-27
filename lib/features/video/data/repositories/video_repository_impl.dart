import 'package:dartz/dartz.dart';
import 'package:melodix/features/video/data/datasources/video_local_storage.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/video/data/datasources/video_service.dart';
import 'package:melodix/features/video/data/mappers/video_mapper.dart';
import 'package:melodix/features/video/data/repositories/video_errors.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/repositories/video_repository.dart';

class VideoRepositoryImpl implements VideoRepository {
  const VideoRepositoryImpl({required this._storage, required this._service});

  final VideoLocalStorage _storage;
  final VideoService _service;

  @override
  Stream<List<Video>> watchVideos() =>
      _storage.watchAllVideos().map(VideoMapper.toEntities);

  @override
  Stream<List<Video>> watchFavoriteVideos() =>
      _storage.watchFavoriteVideos().map(VideoMapper.toEntities);

  @override
  Future<Either<Failure, bool>> toggleFavorite(String videoId) async {
    try {
      return Right(await _storage.toggleFavorite(videoId));
    } catch (e, stack) {
      logVideoProblem('Could not toggle a video favourite', e, stack);
      return const Left(LibraryFailure(VideoErrors.write));
    }
  }

  @override
  Future<Either<Failure, Unit>> setFavorite(
    List<String> videoIds, {
    required bool favorite,
  }) async {
    try {
      await _storage.setFavorites(videoIds, favorite: favorite);
      return const Right(unit);
    } catch (e, stack) {
      logVideoProblem('Could not change video favourites', e, stack);
      return const Left(LibraryFailure(VideoErrors.write));
    }
  }

  @override
  Future<Either<Failure, List<String>>> deleteVideos(
    List<String> videoIds,
  ) async {
    final List<String> deleted;
    try {
      deleted = await _service.delete(videoIds);
    } catch (e, stack) {
      logVideoProblem('Could not delete videos', e, stack);
      return const Left(LibraryFailure(VideoErrors.delete));
    }
    try {
      // Only what the device really deleted (the user may have said no).
      if (deleted.isNotEmpty) await _storage.removeVideos(deleted);
    } catch (e, stack) {
      // Gone from the device anyway: the next scan tidies the library.
      logVideoProblem('Deleted videos still listed until next scan', e, stack);
    }
    return Right(deleted);
  }
}
