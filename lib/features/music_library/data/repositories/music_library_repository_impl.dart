import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/database/playlist_local_storage.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/service/music_service.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:melodix/features/music_library/data/mappers/library_grouping.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/entities/library_search_results.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_result.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class MusicLibraryRepositoryImpl implements MusicLibraryRepository {
  MusicLibraryRepositoryImpl({
    required this._musicService,
    required this._storage,
    required this._permissionService,
    required this._playlistStorage,
    SongMapper? mapper,
  }) : _mapper = mapper ?? SongMapper(isAndroid: Platform.isAndroid);

  final MusicService _musicService;
  final MusicLocalStorage _storage;
  final PermissionHandlingService _permissionService;
  final PlaylistLocalStorage _playlistStorage;
  final SongMapper _mapper;

  /// Recently loaded artwork, keyed by "songId:size", oldest first. Null
  /// values remember songs without artwork so they aren't queried again.
  final LinkedHashMap<String, Uint8List?> _artworkCache = LinkedHashMap();
  static const int _artworkCacheSize = 300;

  /// The scan currently running, shared by concurrent [syncLibrary] calls.
  Future<Either<Failure, LibrarySyncResult>>? _inFlightSync;

  static const String _syncError = 'Could not read your music library';
  static const String _readError = 'Could not load your music';
  static const String _writeError = 'Could not save your change';
  static const String _deleteError = 'Could not delete the songs';
  static const String _permissionError =
      'Allow access to your music to see your library';

  @override
  Future<LibraryPermission> checkPermission() async =>
      _toLibraryPermission(await _permissionService.audioStatus());

  @override
  Future<LibraryPermission> requestPermission() async =>
      _toLibraryPermission(await _permissionService.requestAudio());

  @override
  Future<bool> openSettings() => _permissionService.openSettings();

  @override
  Future<Uint8List?> getArtwork(int songId, {int size = 200}) async {
    final key = '$songId:$size';
    if (_artworkCache.containsKey(key)) {
      // Move to the end (most recently used).
      final cached = _artworkCache.remove(key);
      _artworkCache[key] = cached;
      return cached;
    }
    Uint8List? artwork;
    try {
      artwork = await _musicService.getArtwork(songId, size: size);
    } catch (_) {
      artwork = null;
    }
    _artworkCache[key] = artwork;
    if (_artworkCache.length > _artworkCacheSize) {
      _artworkCache.remove(_artworkCache.keys.first);
    }
    return artwork;
  }

  @override
  Future<Either<Failure, LibrarySyncResult>> syncLibrary() {
    return _inFlightSync ??= _sync().whenComplete(() => _inFlightSync = null);
  }

  Future<Either<Failure, LibrarySyncResult>> _sync() async {
    try {
      final scanned = await _musicService.getAllSongs();
      final result = await _storage.syncSongs(scanned);
      return Right(
        LibrarySyncResult(
          added: result.added,
          updated: result.updated,
          removed: result.removed,
          total: result.total,
          syncedAt: await _storage.getLastSyncedAt() ?? DateTime.now(),
        ),
      );
    } on MediaPermissionException catch (e) {
      return Left(
        PermissionFailure(
          _permissionError,
          permanentlyDenied: e.permanentlyDenied,
        ),
      );
    } catch (_) {
      return const Left(LibraryFailure(_syncError));
    }
  }

  @override
  Future<DateTime?> lastSyncedAt() => _storage.getLastSyncedAt();

  @override
  Stream<List<Song>> watchSongs() => _storage.watchAllSongs().map(
    (rows) => rows.map(_mapper.toEntity).toList(growable: false),
  );

  @override
  Future<Either<Failure, List<Album>>> getAlbums() =>
      _read(() async => LibraryGrouping.albums(await _storage.getAllSongs()));

  @override
  Future<Either<Failure, List<Artist>>> getArtists() =>
      _read(() async => LibraryGrouping.artists(await _storage.getAllSongs()));

  @override
  Future<Either<Failure, List<Song>>> getAlbumSongs(Album album) =>
      _read(() async {
        final rows = await _storage.getSongsByAlbum(
          albumId: album.albumId,
          albumTitle: album.title,
        );
        return rows.map(_mapper.toEntity).toList(growable: false);
      });

  @override
  Future<Either<Failure, List<Song>>> getArtistSongs(String artistName) =>
      _read(() async {
        final rows = await _storage.getSongsByArtist(artistName);
        return rows.map(_mapper.toEntity).toList(growable: false);
      });

  @override
  Future<Either<Failure, bool>> toggleFavorite(int songId) =>
      _write(() => _storage.toggleFavorite(songId));

  @override
  Future<Either<Failure, Unit>> setSongHidden(
    int songId, {
    required bool hidden,
  }) => _write(() async {
    await _storage.setHidden(songId, hidden: hidden);
    return unit;
  });

  @override
  Stream<List<Song>> watchHiddenSongs() => _storage.watchHiddenSongs().map(
    (rows) => rows.map(_mapper.toEntity).toList(growable: false),
  );

  @override
  Future<Either<Failure, Album?>> getAlbumForSong(Song song) => _read(() async {
    final rows = await _storage.getSongsByAlbum(
      albumId: song.albumId,
      albumTitle: song.album,
    );
    final albums = LibraryGrouping.albums(rows);
    return albums.isEmpty ? null : albums.first;
  });

  @override
  Future<Either<Failure, Artist?>> getArtist(String name) => _read(() async {
    final artists = LibraryGrouping.artists(
      await _storage.getSongsByArtist(name),
    );
    return artists.isEmpty ? null : artists.first;
  });

  @override
  Future<Either<Failure, List<Playlist>>> getPlaylists() => _read(() async {
    final rows = await _playlistStorage.getAllPlaylists();
    return rows.map(_toPlaylist).toList(growable: false);
  });

  @override
  Future<Either<Failure, int>> createPlaylist(
    String name, {
    List<int> songIds = const [],
  }) => _write(() => _playlistStorage.createPlaylist(name, songIds: songIds));

  @override
  Future<Either<Failure, int>> addSongsToPlaylist(
    int playlistId,
    List<int> songIds,
  ) => _write(() => _playlistStorage.addSongs(playlistId, songIds));

  @override
  Stream<List<Playlist>> watchPlaylists() => _playlistStorage
      .watchAllPlaylists()
      .map((rows) => rows.map(_toPlaylist).toList(growable: false));

  @override
  Future<Either<Failure, List<Song>>> getPlaylistSongs(int playlistId) =>
      _read(() async {
        final rows = await _playlistStorage.getPlaylistSongs(playlistId);
        return rows.map(_mapper.toEntity).toList(growable: false);
      });

  @override
  Future<Either<Failure, Unit>> renamePlaylist(int playlistId, String name) =>
      _write(() async {
        await _playlistStorage.renamePlaylist(playlistId, name);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deletePlaylist(int playlistId) =>
      _write(() async {
        await _playlistStorage.deletePlaylist(playlistId);
        return unit;
      });

  @override
  Future<Either<Failure, bool>> togglePlaylistFavorite(int playlistId) =>
      _write(() => _playlistStorage.toggleFavorite(playlistId));

  @override
  Future<Either<Failure, Unit>> removeSongFromPlaylist(
    int playlistId,
    int songId,
  ) => _write(() async {
    await _playlistStorage.removeSong(playlistId, songId);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> reorderPlaylistSongs(
    int playlistId,
    List<int> orderedSongIds,
  ) => _write(() async {
    await _playlistStorage.reorderSongs(playlistId, orderedSongIds);
    return unit;
  });

  @override
  Future<Either<Failure, LibrarySearchResults>> searchLibrary(String query) =>
      _read(() async {
        final q = query.trim().toLowerCase();
        if (q.isEmpty) return LibrarySearchResults.empty;
        bool matches(String value) => value.toLowerCase().contains(q);

        // One read of the visible library feeds songs, artists and albums.
        final rows = await _storage.getAllSongs();
        final songs = [
          for (final row in rows)
            if (matches(row.title) || matches(row.artist) || matches(row.album))
              _mapper.toEntity(row),
        ];
        final artists = LibraryGrouping.artists(rows)
            .where((a) => matches(a.name))
            .toList(growable: false);
        final albums = LibraryGrouping.albums(rows)
            .where((a) => matches(a.title) || matches(a.artist))
            .toList(growable: false);
        final playlists = [
          for (final p in await _playlistStorage.getAllPlaylists())
            if (matches(p.name)) _toPlaylist(p),
        ];

        return LibrarySearchResults(
          songs: songs,
          artists: artists,
          albums: albums,
          playlists: playlists,
        );
      });

  @override
  Future<Either<Failure, Unit>> recordPlay(int songId) => _write(() async {
    await _storage.recordPlay(songId);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> setSongsHidden(
    List<int> songIds, {
    required bool hidden,
  }) => _write(() async {
    await _storage.setHiddenMany(songIds, hidden: hidden);
    return unit;
  });

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
  Future<Either<Failure, int>> deleteSongs(List<int> songIds) async {
    try {
      final deleted = await _musicService.deleteSongs(songIds);
      if (deleted.isNotEmpty) await _storage.removeSongs(deleted);
      return Right(deleted.length);
    } catch (_) {
      return const Left(LibraryFailure(_deleteError));
    }
  }

  static Playlist _toPlaylist(PlaylistCollection p) => Playlist(
    id: p.id,
    name: p.name,
    songCount: p.songCount,
    isFavorite: p.isFavorite,
    artworkSongId: p.songIds.isEmpty ? null : p.songIds.first,
  );

  Future<Either<Failure, T>> _write<T>(Future<T> Function() change) async {
    try {
      return Right(await change());
    } catch (_) {
      return const Left(LibraryFailure(_writeError));
    }
  }

  Future<Either<Failure, T>> _read<T>(Future<T> Function() query) async {
    try {
      return Right(await query());
    } catch (_) {
      return const Left(LibraryFailure(_readError));
    }
  }

  static LibraryPermission _toLibraryPermission(MediaPermissionStatus s) {
    switch (s) {
      case MediaPermissionStatus.granted:
        return LibraryPermission.granted;
      case MediaPermissionStatus.denied:
        return LibraryPermission.denied;
      case MediaPermissionStatus.permanentlyDenied:
        return LibraryPermission.permanentlyDenied;
    }
  }
}
