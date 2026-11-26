import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

/// The songs the user played last (recorded by the player as songs start).
abstract interface class RecentlyPlayedRepository {
  /// Newest first (up to 50), now and whenever a song is played. Hidden or
  /// deleted songs are left out.
  Stream<List<Song>> watchRecentlyPlayed();

  /// Forgets the history. Play counts ("Most played") are kept.
  Future<Either<Failure, Unit>> clearRecentlyPlayed();
}
