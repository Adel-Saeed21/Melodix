import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/error_messages.dart';
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
  static const String sync = ErrorMessages.librarySync;
  static const String read = ErrorMessages.libraryRead;
  static const String write = ErrorMessages.write;
  static const String delete = ErrorMessages.songsDelete;
  static const String permission = ErrorMessages.libraryPermission;
}
