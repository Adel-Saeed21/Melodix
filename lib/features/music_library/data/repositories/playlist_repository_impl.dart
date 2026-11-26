import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/core/database/playlist_local_storage.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/data/mappers/playlist_mapper.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/music_library/data/repositories/repository_guard.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/repositories/playlist_repository.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  const PlaylistRepositoryImpl({required this._storage, required this._mapper});

  final PlaylistLocalStorage _storage;
  final SongMapper _mapper;

  @override
  Future<Either<Failure, List<Playlist>>> getPlaylists() =>
      _read(() async => _toPlaylists(await _storage.getAllPlaylists()));

  /// The playlists now, and again whenever they change.
  @override
  Stream<List<Playlist>> watchPlaylists() =>
      _storage.watchAllPlaylists().map(_toPlaylists);

  @override
  Future<Either<Failure, int>> createPlaylist(
    String name, {
    List<int> songIds = const [],
  }) => _write(() => _storage.createPlaylist(name, songIds: songIds));

  @override
  Future<Either<Failure, int>> addSongsToPlaylist(
    int playlistId,
    List<int> songIds,
  ) => _write(() => _storage.addSongs(playlistId, songIds));

  @override
  Future<Either<Failure, List<Song>>> getPlaylistSongs(int playlistId) =>
      _read(() async {
        final rows = await _storage.getPlaylistSongs(playlistId);
        return rows.map(_mapper.toEntity).toList(growable: false);
      });

  @override
  Future<Either<Failure, Unit>> renamePlaylist(int playlistId, String name) =>
      _write(() async {
        await _storage.renamePlaylist(playlistId, name);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deletePlaylist(int playlistId) =>
      _write(() async {
        await _storage.deletePlaylist(playlistId);
        return unit;
      });

  @override
  Future<Either<Failure, bool>> togglePlaylistFavorite(int playlistId) =>
      _write(() => _storage.toggleFavorite(playlistId));

  @override
  Future<Either<Failure, Unit>> removeSongFromPlaylist(
    int playlistId,
    int songId,
  ) => _write(() async {
    await _storage.removeSong(playlistId, songId);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> reorderPlaylistSongs(
    int playlistId,
    List<int> orderedSongIds,
  ) => _write(() async {
    await _storage.reorderSongs(playlistId, orderedSongIds);
    return unit;
  });

  static List<Playlist> _toPlaylists(List<PlaylistCollection> rows) => [
    for (final row in rows) PlaylistMapper.toEntity(row),
  ];

  static Future<Either<Failure, T>> _read<T>(Future<T> Function() query) =>
      guardRepositoryCall(query, errorMessage: LibraryErrors.read);

  static Future<Either<Failure, T>> _write<T>(Future<T> Function() change) =>
      guardRepositoryCall(change, errorMessage: LibraryErrors.write);
}
