import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/video/domain/repositories/video_library_repository.dart';

/// Params: the video id. Returns the new favourite value.
class ToggleVideoFavoriteUseCase implements UseCase<bool, String> {
  const ToggleVideoFavoriteUseCase(this.repository);

  final VideoLibraryRepository repository;

  @override
  Future<Either<Failure, bool>> call(String videoId) =>
      repository.toggleFavorite(videoId);
}
