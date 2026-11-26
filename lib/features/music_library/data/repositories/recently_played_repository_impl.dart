import 'package:dartz/dartz.dart';
import 'package:melodix/core/database/recent_music_local_storage.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/music_library/data/repositories/repository_guard.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/repositories/recently_played_repository.dart';

class RecentlyPlayedRepositoryImpl implements RecentlyPlayedRepository {
  const RecentlyPlayedRepositoryImpl({
    required this._storage,
    required this._mapper,
  });

  final RecentMusicLocalStorage _storage;
  final SongMapper _mapper;

  @override
  Stream<List<Song>> watchRecentlyPlayed() => _storage.watchRecentSongs().map(
    (rows) => rows.map(_mapper.toEntity).toList(growable: false),
  );

  @override
  Future<Either<Failure, Unit>> clearRecentlyPlayed() =>
      guardRepositoryCall(errorMessage: LibraryErrors.write, () async {
        await _storage.clearRecent();
        return unit;
      });
}
