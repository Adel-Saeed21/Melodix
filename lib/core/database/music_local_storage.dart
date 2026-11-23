import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/library_metadata_collection.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/core/database/collections/recent_music_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/recent_music_local_storage.dart';
import 'package:melodix/core/models/local_song.dart';

/// What a library sync changed.
class SongSyncResult {
  const SongSyncResult({
    required this.added,
    required this.updated,
    required this.removed,
    required this.total,
  });

  final int added;
  final int updated;
  final int removed;

  /// Songs in the library after the sync.
  final int total;

  bool get hasChanges => added > 0 || updated > 0 || removed > 0;
}

/// Persists the device's music library and the user's data for each song.
abstract interface class MusicLocalStorage {
  /// Saves a fresh device scan:
  /// * adds new songs and rewrites only songs whose metadata changed;
  /// * removes songs that are gone, including from recents and playlists;
  /// * keeps favorites and play counts;
  /// * records the sync time ([getLastSyncedAt]).
  Future<SongSyncResult> syncSongs(List<LocalSong> scanned);

  /// When the library was last synced, or null if it never was.
  Future<DateTime?> getLastSyncedAt();

  Future<List<SongCollection>> getAllSongs();

  /// Emits the visible library (sorted by title) now and on every change.
  /// Hidden songs are excluded here and in every other query below.
  Stream<List<SongCollection>> watchAllSongs();

  /// Case-insensitive match on title, artist or album.
  Future<List<SongCollection>> searchSongs(String query);

  /// Songs of one album, sorted by title. Uses [albumId] when known,
  /// otherwise matches the album name (case-insensitive).
  Future<List<SongCollection>> getSongsByAlbum({
    int? albumId,
    required String albumTitle,
  });

  /// Songs by one artist (case-insensitive), sorted by album then title.
  Future<List<SongCollection>> getSongsByArtist(String artist);

  /// Flips the favorite flag and returns the new value.
  Future<bool> toggleFavorite(int songId);

  /// Hides a song from the library (or shows it again). The file is never
  /// touched.
  Future<void> setHidden(int songId, {required bool hidden});

  /// Songs the user hid, sorted by title, now and on every change.
  Stream<List<SongCollection>> watchHiddenSongs();

  /// Hides (or shows) several songs at once.
  Future<void> setHiddenMany(List<int> songIds, {required bool hidden});

  /// Marks (or unmarks) several songs as favourites at once.
  Future<void> setFavoriteMany(List<int> songIds, {required bool favorite});

  /// Forgets songs whose files were deleted: removes them from the library,
  /// recents and playlists.
  Future<void> removeSongs(List<int> songIds);

  /// Increments the play count and moves the song to the top of the
  /// recently played list (see [RecentMusicLocalStorage]).
  Future<void> recordPlay(int songId);
}

class MusicLocalStorageImpl implements MusicLocalStorage {
  MusicLocalStorageImpl(this._isar);

  final Isar _isar;

  IsarCollection<SongCollection> get _songs => _isar.songCollections;

  IsarCollection<RecentMusicCollection> get _recent =>
      _isar.recentMusicCollections;

  IsarCollection<PlaylistCollection> get _playlists =>
      _isar.playlistCollections;

  IsarCollection<LibraryMetadataCollection> get _metadata =>
      _isar.libraryMetadataCollections;

  @override
  Future<SongSyncResult> syncSongs(List<LocalSong> scanned) {
    return _isar.writeTxn(() async {
      final existing = await _songs.where().findAll();
      final previousById = {for (final s in existing) s.id: s};
      final scannedIds = <int>{};

      var added = 0;
      var updated = 0;
      final toWrite = <SongCollection>[];
      for (final song in scanned) {
        if (!scannedIds.add(song.id)) continue; // duplicate in scan
        final previous = previousById[song.id];
        final row = SongCollection.fromLocalSong(song, previous: previous);
        if (previous == null) {
          added++;
          toWrite.add(row);
        } else if (!previous.hasSameScanData(row)) {
          updated++;
          toWrite.add(row);
        }
      }
      if (toWrite.isNotEmpty) await _songs.putAll(toWrite);

      final removedIds = [
        for (final s in existing)
          if (!scannedIds.contains(s.id)) s.id,
      ];
      if (removedIds.isNotEmpty) await _forget(removedIds);

      final metadata =
          await _metadata.get(LibraryMetadataCollection.singletonId) ??
          LibraryMetadataCollection();
      metadata.lastSongSyncAt = DateTime.now();
      await _metadata.put(metadata);

      return SongSyncResult(
        added: added,
        updated: updated,
        removed: removedIds.length,
        total: scannedIds.length,
      );
    });
  }

  /// Removes songs from the library, recents and playlists. Call inside a
  /// write transaction.
  Future<void> _forget(List<int> songIds) async {
    await _songs.deleteAll(songIds);
    await _recent.deleteAll(songIds);
    await _removeFromPlaylists(songIds.toSet());
  }

  /// Drops deleted songs from every playlist that contains them. Call inside
  /// a write transaction.
  Future<void> _removeFromPlaylists(Set<int> removedIds) async {
    final playlists = await _playlists.where().findAll();
    final changed = <PlaylistCollection>[];
    for (final playlist in playlists) {
      if (!playlist.songIds.any(removedIds.contains)) continue;
      playlist.songIds = [
        for (final id in playlist.songIds)
          if (!removedIds.contains(id)) id,
      ];
      changed.add(playlist);
    }
    if (changed.isNotEmpty) await _playlists.putAll(changed);
  }

  @override
  Future<DateTime?> getLastSyncedAt() async =>
      (await _metadata.get(LibraryMetadataCollection.singletonId))
          ?.lastSongSyncAt;

  @override
  Future<List<SongCollection>> getAllSongs() =>
      _songs.filter().not().isHiddenEqualTo(true).sortByTitle().findAll();

  @override
  Stream<List<SongCollection>> watchAllSongs() => _songs
      .filter()
      .not()
      .isHiddenEqualTo(true)
      .sortByTitle()
      .watch(fireImmediately: true);

  @override
  Future<List<SongCollection>> searchSongs(String query) {
    final q = query.trim();
    if (q.isEmpty) return getAllSongs();
    return _songs
        .filter()
        .not()
        .isHiddenEqualTo(true)
        .group(
          (s) => s
              .titleContains(q, caseSensitive: false)
              .or()
              .artistContains(q, caseSensitive: false)
              .or()
              .albumContains(q, caseSensitive: false),
        )
        .sortByTitle()
        .findAll();
  }

  @override
  Future<List<SongCollection>> getSongsByAlbum({
    int? albumId,
    required String albumTitle,
  }) {
    if (albumId != null) {
      return _songs
          .where()
          .albumIdEqualTo(albumId)
          .filter()
          .not()
          .isHiddenEqualTo(true)
          .sortByTitle()
          .findAll();
    }
    return _songs
        .where()
        .albumEqualTo(albumTitle)
        .filter()
        .not()
        .isHiddenEqualTo(true)
        .sortByTitle()
        .findAll();
  }

  @override
  Future<List<SongCollection>> getSongsByArtist(String artist) => _songs
      .where()
      .artistEqualTo(artist)
      .filter()
      .not()
      .isHiddenEqualTo(true)
      .sortByAlbum()
      .thenByTitle()
      .findAll();

  @override
  Future<bool> toggleFavorite(int songId) {
    return _isar.writeTxn(() async {
      final song = await _songs.get(songId);
      if (song == null) return false;
      song.isFavorite = !song.isFavorite;
      await _songs.put(song);
      return song.isFavorite;
    });
  }

  @override
  Future<void> setHidden(int songId, {required bool hidden}) {
    return _isar.writeTxn(() async {
      final song = await _songs.get(songId);
      if (song == null || song.isHidden == hidden) return;
      song.isHidden = hidden;
      await _songs.put(song);
    });
  }

  @override
  Future<void> setHiddenMany(List<int> songIds, {required bool hidden}) =>
      _updateMany(songIds, (song) => song.isHidden = hidden);

  @override
  Future<void> setFavoriteMany(List<int> songIds, {required bool favorite}) =>
      _updateMany(songIds, (song) => song.isFavorite = favorite);

  @override
  Future<void> removeSongs(List<int> songIds) async {
    if (songIds.isEmpty) return;
    await _isar.writeTxn(() => _forget(songIds));
  }

  Future<void> _updateMany(
    List<int> songIds,
    void Function(SongCollection song) change,
  ) async {
    if (songIds.isEmpty) return;
    await _isar.writeTxn(() async {
      final songs = (await _songs.getAll(songIds)).whereType<SongCollection>();
      for (final song in songs) {
        change(song);
      }
      await _songs.putAll(songs.toList());
    });
  }

  @override
  Stream<List<SongCollection>> watchHiddenSongs() => _songs
      .filter()
      .isHiddenEqualTo(true)
      .sortByTitle()
      .watch(fireImmediately: true);

  @override
  Future<void> recordPlay(int songId) {
    return _isar.writeTxn(() async {
      final song = await _songs.get(songId);
      if (song == null) return;
      song.playCount += 1;
      await _songs.put(song);

      await _recent.put(RecentMusicCollection.played(songId));
      await _trimRecent();
    });
  }

  /// Drops the oldest recent entries beyond the cap. Call inside a write
  /// transaction.
  Future<void> _trimRecent() async {
    final overflow = await _recent
        .where()
        .sortByPlayedAtDesc()
        .offset(RecentMusicLocalStorage.maxEntries)
        .idProperty()
        .findAll();
    if (overflow.isNotEmpty) await _recent.deleteAll(overflow);
  }
}
