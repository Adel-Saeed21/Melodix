import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/video/domain/repositories/video_repository.dart';

/// Makes several videos favourites (or not) at once.
class SetVideosFavoriteUseCase {
  const SetVideosFavoriteUseCase(this.repository);

  final VideoRepository repository;

  Future<Either<Failure, Unit>> call(
    List<String> videoIds, {
    required bool favorite,
  }) => repository.setFavorite(videoIds, favorite: favorite);
}

/// Deletes videos from the device (the system may ask first). Returns the
/// ids actually deleted.
class DeleteVideosUseCase {
  const DeleteVideosUseCase(this.repository);

  final VideoRepository repository;

  Future<Either<Failure, List<String>>> call(List<String> videoIds) =>
      repository.deleteVideos(videoIds);
}
