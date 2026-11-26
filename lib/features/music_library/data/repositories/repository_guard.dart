import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';

/// Runs a repository operation and turns any error into a [LibraryFailure]
/// with the user-facing [errorMessage]. One place for the try/catch that
/// every simple read and write needs.
Future<Either<Failure, T>> guardRepositoryCall<T>(
  Future<T> Function() operation, {
  required String errorMessage,
}) async {
  try {
    return Right(await operation());
  } catch (_) {
    return Left(LibraryFailure(errorMessage));
  }
}

/// User-facing messages shared by the music library repositories.
abstract final class LibraryErrors {
  static const String sync = 'Could not read your music library';
  static const String read = 'Could not load your music';
  static const String write = 'Could not save your change';
  static const String delete = 'Could not delete the songs';
  static const String permission =
      'Allow access to your music to see your library';
}
