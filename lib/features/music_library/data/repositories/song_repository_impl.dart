import 'package:dartz/dartz.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/database/song_library_update.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/service/music_service.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/music_library/data/repositories/repository_guard.dart';
import 'package:melodix/features/music_library/domain/entities/library_update.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/repositories/song_repository.dart';

class SongRepositoryImpl implements SongRepository {
  const SongRepositoryImpl({
    required this._storage,
    required this._musicService,
    required this._mapper,
  });

  final MusicLocalStorage _storage;
  final MusicService _musicService;
  final SongMapper _mapper;

  @override
  Stream<LibraryUpdate> watchLibrary() => _storage.watchLibrary().map(
    (update) => switch (update) {
      SongLibraryLoaded(:final songs) => LibraryReloaded(_toSongs(songs)),
      SongLibrarySongsChanged(:final songs) => LibrarySongsUpdated(
        _toSongs(songs),
      ),
      SongLibrarySongsRemoved(:final ids) => LibrarySongsRemoved(ids),
    },
  );

  @override
  Stream<bool> watchFavorite(int songId) => _storage.watchFavorite(songId);

  @override
  Future<Either<Failure, bool>> toggleFavorite(int songId) =>
      _write(() => _storage.toggleFavorite(songId));

  @override
  Future<Either<Failure, Unit>> setSongsFavorite(
    List<int> songIds, {
    required bool favorite,
  }) => _write(() async {
    await _storage.setFavoriteMany(songIds, favorite: favorite);
    return unit;
  });

  @override
  bool get canDeleteSongs => _musicService.canDeleteSongs;

  @override
  Future<Either<Failure, int>> deleteSongs(List<int> songIds) =>
      guardRepositoryCall(errorMessage: LibraryErrors.delete, () async {
        // Only what the device actually deleted (the user may decline).
        final deleted = await _musicService.deleteSongs(songIds);
        if (deleted.isNotEmpty) await _storage.removeSongs(deleted);
        return deleted.length;
      });

  List<Song> _toSongs(List<SongCollection> rows) =>
      rows.map(_mapper.toEntity).toList(growable: false);

  static Future<Either<Failure, T>> _write<T>(Future<T> Function() change) =>
      guardRepositoryCall(change, errorMessage: LibraryErrors.write);
}
