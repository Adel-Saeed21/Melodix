import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';

/// Creates and edits the user's playlists.
abstract interface class PlaylistLocalStorage {
  /// Creates an empty playlist (or one starting with [songIds]) and returns
  /// its id.
  Future<int> createPlaylist(String name, {List<int> songIds = const []});

  Future<void> renamePlaylist(int playlistId, String name);

  Future<void> deletePlaylist(int playlistId);

  Future<PlaylistCollection?> getPlaylist(int playlistId);

  /// All playlists, most recently changed first.
  Future<List<PlaylistCollection>> getAllPlaylists();

  /// Emits all playlists (most recently changed first) now and on change.
  Stream<List<PlaylistCollection>> watchAllPlaylists();

  /// The playlist's songs in order, skipping songs no longer on the device.
  Future<List<SongCollection>> getPlaylistSongs(int playlistId);

  /// Adds songs that aren't already in the playlist; returns how many.
  Future<int> addSongs(int playlistId, List<int> songIds);

  Future<void> removeSong(int playlistId, int songId);

  Future<void> moveSong(int playlistId, int from, int to);

  /// Saves a new order for the visible songs; hidden songs keep their
  /// positions (see [PlaylistCollection.reorderVisible]).
  Future<void> reorderSongs(int playlistId, List<int> orderedSongIds);

  /// Flips the favorite flag and returns the new value.
  Future<bool> toggleFavorite(int playlistId);
}

class PlaylistLocalStorageImpl implements PlaylistLocalStorage {
  PlaylistLocalStorageImpl(this._isar);

  final Isar _isar;

  IsarCollection<PlaylistCollection> get _playlists =>
      _isar.playlistCollections;

  @override
  Future<int> createPlaylist(String name, {List<int> songIds = const []}) {
    final playlist = PlaylistCollection.create(name)..addSongs(songIds);
    return _isar.writeTxn(() => _playlists.put(playlist));
  }

  @override
  Future<void> renamePlaylist(int playlistId, String name) =>
      _update(playlistId, (p) => p.rename(name));

  @override
  Future<void> deletePlaylist(int playlistId) =>
      _isar.writeTxn(() => _playlists.delete(playlistId));

  @override
  Future<PlaylistCollection?> getPlaylist(int playlistId) =>
      _playlists.get(playlistId);

  @override
  Future<List<PlaylistCollection>> getAllPlaylists() =>
      _playlists.where().sortByUpdatedAtDesc().findAll();

  @override
  Stream<List<PlaylistCollection>> watchAllPlaylists() =>
      _playlists.where().sortByUpdatedAtDesc().watch(fireImmediately: true);

  @override
  Future<List<SongCollection>> getPlaylistSongs(int playlistId) async {
    final playlist = await _playlists.get(playlistId);
    if (playlist == null || playlist.songIds.isEmpty) return const [];
    final songs = await _isar.songCollections.getAll(playlist.songIds);
    return songs
        .whereType<SongCollection>()
        .where((s) => !s.isHidden)
        .toList(growable: false);
  }

  @override
  Future<int> addSongs(int playlistId, List<int> songIds) async {
    var added = 0;
    await _update(playlistId, (p) => added = p.addSongs(songIds));
    return added;
  }

  @override
  Future<void> removeSong(int playlistId, int songId) =>
      _update(playlistId, (p) => p.removeSong(songId));

  @override
  Future<void> moveSong(int playlistId, int from, int to) =>
      _update(playlistId, (p) => p.moveSong(from, to));

  @override
  Future<void> reorderSongs(int playlistId, List<int> orderedSongIds) =>
      _update(playlistId, (p) => p.reorderVisible(orderedSongIds));

  @override
  Future<bool> toggleFavorite(int playlistId) async {
    var isFavorite = false;
    await _update(playlistId, (p) => isFavorite = p.isFavorite = !p.isFavorite);
    return isFavorite;
  }

  /// Loads, mutates and saves a playlist in one transaction.
  Future<void> _update(
    int playlistId,
    void Function(PlaylistCollection playlist) change,
  ) {
    return _isar.writeTxn(() async {
      final playlist = await _playlists.get(playlistId);
      if (playlist == null) return;
      change(playlist);
      await _playlists.put(playlist);
    });
  }
}
