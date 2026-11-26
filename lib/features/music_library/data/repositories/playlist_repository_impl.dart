import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/database/playlist_local_storage.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/data/mappers/playlist_mapper.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/music_library/data/repositories/repository_guard.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/repositories/playlist_repository.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  const PlaylistRepositoryImpl({
    required this._storage,
    required this._songStorage,
    required this._mapper,
  });

  final PlaylistLocalStorage _storage;

  /// Which songs are hidden: they don't count towards a playlist's songs.
  final MusicLocalStorage _songStorage;
  final SongMapper _mapper;

  @override
  Future<Either<Failure, List<Playlist>>> getPlaylists() => _read(() async {
    final rows = await _storage.getAllPlaylists();
    final hidden = await _songStorage.watchHiddenSongs().first;
    return _toPlaylists(rows, _ids(hidden));
  });

  /// Re-emits when the playlists change and when songs are hidden or
  /// unhidden (counts and covers depend on both).
  @override
  Stream<List<Playlist>> watchPlaylists() {
    late final StreamController<List<Playlist>> out;
    StreamSubscription<void>? playlists;
    StreamSubscription<void>? hidden;
    List<PlaylistCollection>? latestRows;
    Set<int>? latestHidden;

    void emitIfReady() {
      final rows = latestRows, hiddenIds = latestHidden;
      if (rows != null && hiddenIds != null) {
        out.add(_toPlaylists(rows, hiddenIds));
      }
    }

    out = StreamController<List<Playlist>>(
      onListen: () {
        playlists = _storage.watchAllPlaylists().listen((rows) {
          latestRows = rows;
          emitIfReady();
        }, onError: out.addError);
        hidden = _songStorage.watchHiddenSongs().listen((songs) {
          latestHidden = _ids(songs);
          emitIfReady();
        }, onError: out.addError);
      },
      onCancel: () async {
        await playlists?.cancel();
        await hidden?.cancel();
      },
    );
    return out.stream;
  }

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

  static List<Playlist> _toPlaylists(
    List<PlaylistCollection> rows,
    Set<int> hiddenSongIds,
  ) => [
    for (final row in rows)
      PlaylistMapper.toEntity(row, hiddenSongIds: hiddenSongIds),
  ];

  static Set<int> _ids(List<SongCollection> songs) => {
    for (final s in songs) s.id,
  };

  static Future<Either<Failure, T>> _read<T>(Future<T> Function() query) =>
      guardRepositoryCall(query, errorMessage: LibraryErrors.read);

  static Future<Either<Failure, T>> _write<T>(Future<T> Function() change) =>
      guardRepositoryCall(change, errorMessage: LibraryErrors.write);
}
