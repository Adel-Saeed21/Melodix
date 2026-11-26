import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/video/domain/entities/video.dart';

/// The saved video library and the user's favourites.
abstract interface class VideoRepository {
  /// All videos, newest first, now and on every change.
  Stream<List<Video>> watchVideos();

  /// The favourite videos, newest first, now and on every change.
  Stream<List<Video>> watchFavoriteVideos();

  /// Flips the video's favourite flag; returns the new value.
  Future<Either<Failure, bool>> toggleFavorite(String videoId);

  /// Makes all [videoIds] favourites, or none of them.
  Future<Either<Failure, Unit>> setFavorite(
    List<String> videoIds, {
    required bool favorite,
  });

  /// Deletes the videos from the device (the system may ask the user
  /// first) and from the library. Returns the ids actually deleted.
  Future<Either<Failure, List<String>>> deleteVideos(List<String> videoIds);
}
