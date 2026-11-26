import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/domain/entities/library_update.dart';

/// The library's songs and what the user can do with them.
abstract interface class SongRepository {
  /// The visible library (sorted by title) as a series of updates: the
  /// whole list first and after library changes (sync), only the
  /// affected songs for single-song edits (favourite, play count,
  /// deleting). Apply them in order with [LibraryUpdate.applyTo].
  Stream<LibraryUpdate> watchLibrary();

  /// Flips the song's favorite flag; returns the new value.
  Future<Either<Failure, bool>> toggleFavorite(int songId);

  /// Whether the song is a favourite, now and whenever that changes.
  Stream<bool> watchFavorite(int songId);

  // Bulk actions (multi-select)

  Future<Either<Failure, Unit>> setSongsFavorite(
    List<int> songIds, {
    required bool favorite,
  });

  /// Whether song files can be deleted on this platform (Android only).
  bool get canDeleteSongs;

  /// Deletes the song files from the device (the system asks the user to
  /// confirm) and removes them from the library. Returns how many were
  /// deleted; 0 if the user declined.
  Future<Either<Failure, int>> deleteSongs(List<int> songIds);
}
