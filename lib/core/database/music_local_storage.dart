import 'package:melodix/core/preferences/library_filter.dart';

import 'dart:async';

import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/library_metadata_collection.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/core/database/collections/recent_music_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/collections/song_history_collection.dart';
import 'package:melodix/core/database/recent_music_local_storage.dart';
import 'package:melodix/core/database/song_library_update.dart';
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
  /// [checkpoint] describes where the device library stood when the scan
  /// started; it's saved in the same transaction as the songs.
  Future<SongSyncResult> syncSongs(
    List<LocalSong> scanned, {
    String? checkpoint,
  });

  /// Applies an incremental scan in one transaction: adds or updates
  /// [upserts] (keeping favourites and play counts), forgets
  /// [deletedIds] (also from recents and playlists) and saves [checkpoint].
  /// If anything fails nothing is saved, so the checkpoint never moves past
  /// changes that weren't applied.
  Future<SongSyncResult> applyChanges({
    required List<LocalSong> upserts,
    required Iterable<int> deletedIds,
    required String checkpoint,
  });

  /// Every saved song id, including songs the library filter leaves out.
  Future<Set<int>> getAllSongIds();

  /// The checkpoint saved by the last sync, if any.
  Future<String?> getSyncCheckpoint();

  /// Records that the library was checked and found unchanged (updates the
  /// last-synced time without scanning).
  Future<void> markCheckedUnchanged();

  /// How many visible songs the library has.
  Future<int> countSongs();

  /// When the library was last synced, or null if it never was.
  Future<DateTime?> getLastSyncedAt();

  Future<List<SongCollection>> getAllSongs();

  /// Sends the whole library again to [watchLibrary] listeners (the
  /// library filter changed).
  void reloadLibrary();

  /// The visible library (sorted by title) as a series of updates: the full
  /// list first, the full list again after changes to the library itself
  /// (sync, unhiding), and only the affected songs for single-song edits
  /// (favourite, play count, hiding, deleting). Updates follow committed
  /// writes in order; a failed write sends nothing.
  Stream<SongLibraryUpdate> watchLibrary();

  /// Flips the favorite flag and returns the new value.
  Future<bool> toggleFavorite(int songId);

  /// Whether the song is a favourite, now and whenever that changes (false
  /// if it's gone). For the media notification's ♥ button.
  Stream<bool> watchFavorite(int songId);

  /// Marks (or unmarks) several songs as favourites at once.
  Future<void> setFavoriteMany(List<int> songIds, {required bool favorite});

  /// Forgets songs whose files were deleted: removes them from the library,
  /// recents and playlists.
  Future<void> removeSongs(List<int> songIds);

  /// Increments the play count and moves the song to the top of the
  /// recently played list (see [RecentMusicLocalStorage]).
  Future<void> recordPlay(int songId);

  /// Adds [listened] to the time the song was really listened to. Nothing
  /// the library shows changes, so no library update is sent.
  Future<void> addListening(int songId, Duration listened);
}

class MusicLocalStorageImpl implements MusicLocalStorage {
  MusicLocalStorageImpl(this._isar, {LibraryFilter Function()? filter})
    : _filter = filter ?? _showAll;

  final Isar _isar;

  static LibraryFilter _showAll() => LibraryFilter.defaults;

  /// What the library shows (Settings › Music filters); read each time.
  final LibraryFilter Function() _filter;

  bool _keeps(SongCollection s) =>
      _filter().keeps(path: s.path, durationMs: s.durationMs);

  /// What each committed write changed, for [watchLibrary]. Every write to
  /// the songs collection goes through this class, so this is complete.
  final StreamController<_LibraryChange> _changes = StreamController.broadcast(
    sync: true,
  );

  IsarCollection<SongCollection> get _songs => _isar.songCollections;

  IsarCollection<SongHistoryCollection> get _history =>
      _isar.songHistoryCollections;

  IsarCollection<RecentMusicCollection> get _recent =>
      _isar.recentMusicCollections;

  IsarCollection<PlaylistCollection> get _playlists =>
      _isar.playlistCollections;

  IsarCollection<LibraryMetadataCollection> get _metadata =>
      _isar.libraryMetadataCollections;

  @override
  Future<SongSyncResult> syncSongs(
    List<LocalSong> scanned, {
    String? checkpoint,
  }) async {
    final result = await _isar.writeTxn(() async {
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
      await _restoreHistory([
        for (final row in toWrite)
          if (!previousById.containsKey(row.id)) row,
      ]);
      if (toWrite.isNotEmpty) await _songs.putAll(toWrite);

      final removedIds = [
        for (final s in existing)
          if (!scannedIds.contains(s.id)) s.id,
      ];
      if (removedIds.isNotEmpty) await _forget(removedIds);

      await _saveSync(checkpoint);

      return SongSyncResult(
        added: added,
        updated: updated,
        removed: removedIds.length,
        total: scannedIds.length,
      );
    });
    if (result.hasChanges) _changes.add(const _Reload());
    return result;
  }

  /// Removes songs from the library, recents and playlists, keeping their
  /// listening history for the stats. Call inside a write transaction.
  Future<void> _forget(List<int> songIds) async {
    final now = DateTime.now();
    final kept = [
      for (final song in await _songs.getAll(songIds))
        if (song != null) ?SongHistoryCollection.of(song, now),
    ];
    if (kept.isNotEmpty) await _history.putAll(kept);
    await _songs.deleteAll(songIds);
    await _recent.deleteAll(songIds);
    await _removeFromPlaylists(songIds.toSet());
  }

  /// Songs back in the library (new rows, not yet saved) get the history
  /// they had when they left. Call inside a write transaction.
  Future<void> _restoreHistory(List<SongCollection> added) async {
    if (added.isEmpty) return;
    final ids = [for (final row in added) row.id];
    final history = await _history.getAll(ids);
    final restored = <int>[];
    for (var i = 0; i < added.length; i++) {
      final saved = history[i];
      if (saved == null) continue;
      saved.restoreInto(added[i]);
      restored.add(saved.id);
    }
    if (restored.isNotEmpty) await _history.deleteAll(restored);
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
  Future<String?> getSyncCheckpoint() async =>
      (await _metadata.get(LibraryMetadataCollection.singletonId))
          ?.songSyncCheckpoint;

  @override
  Future<Set<int>> getAllSongIds() async =>
      (await _songs.where().idProperty().findAll()).toSet();

  @override
  Future<SongSyncResult> applyChanges({
    required List<LocalSong> upserts,
    required Iterable<int> deletedIds,
    required String checkpoint,
  }) async {
    final result = await _isar.writeTxn(() async {
      final ids = [for (final song in upserts) song.id];
      final previous = await _songs.getAll(ids);
      var added = 0;
      var updated = 0;
      final toWrite = <SongCollection>[];
      final returning = <SongCollection>[];
      for (var i = 0; i < upserts.length; i++) {
        final before = previous[i];
        final row = SongCollection.fromLocalSong(upserts[i], previous: before);
        if (before == null) {
          added++;
          toWrite.add(row);
          returning.add(row);
        } else if (!before.hasSameScanData(row)) {
          updated++;
          toWrite.add(row);
        }
      }
      await _restoreHistory(returning);
      if (toWrite.isNotEmpty) await _songs.putAll(toWrite);

      final removed = deletedIds.toSet()..removeAll(ids);
      final existingRemoved = (await _songs.getAll(removed.toList()))
          .whereType<SongCollection>()
          .map((s) => s.id)
          .toList();
      if (existingRemoved.isNotEmpty) await _forget(existingRemoved);

      await _saveSync(checkpoint);
      return SongSyncResult(
        added: added,
        updated: updated,
        removed: existingRemoved.length,
        total: await _songs.count(),
      );
    });
    if (result.hasChanges) _changes.add(const _Reload());
    return result;
  }

  /// Records a completed sync and its checkpoint. Call inside a write
  /// transaction.
  Future<void> _saveSync(String? checkpoint) async {
    final metadata =
        await _metadata.get(LibraryMetadataCollection.singletonId) ??
        LibraryMetadataCollection();
    metadata
      ..lastSongSyncAt = DateTime.now()
      ..songSyncCheckpoint = checkpoint;
    await _metadata.put(metadata);
  }

  @override
  Future<void> markCheckedUnchanged() => _isar.writeTxn(() async {
    final metadata =
        await _metadata.get(LibraryMetadataCollection.singletonId) ??
        LibraryMetadataCollection();
    metadata.lastSongSyncAt = DateTime.now();
    await _metadata.put(metadata);
  });

  @override
  Future<int> countSongs() async =>
      _filter().isDefault ? _songs.count() : (await getAllSongs()).length;

  @override
  Future<DateTime?> getLastSyncedAt() async =>
      (await _metadata.get(LibraryMetadataCollection.singletonId))
          ?.lastSongSyncAt;

  @override
  Future<List<SongCollection>> getAllSongs() async {
    final songs = await _songs.where().sortByTitle().findAll();
    if (_filter().isDefault) return songs;
    return songs.where(_keeps).toList(growable: false);
  }

  @override
  void reloadLibrary() => _changes.add(const _Reload());

  @override
  Stream<SongLibraryUpdate> watchLibrary() {
    late final StreamController<SongLibraryUpdate> out;
    StreamSubscription<_LibraryChange>? changes;
    // Steps run one after another, so updates keep the order of the writes
    // (a full reload is never overtaken by a later single-song change).
    var queue = Future<void>.value();
    var reloadsQueued = 0;

    void enqueue(Future<SongLibraryUpdate?> Function() step) {
      queue = queue.then((_) async {
        if (out.isClosed) return;
        try {
          final update = await step();
          if (update != null && !out.isClosed) out.add(update);
        } catch (e, stack) {
          if (!out.isClosed) out.addError(e, stack);
        }
      });
    }

    void reload() {
      reloadsQueued++;
      enqueue(() async {
        // A later reload is queued: it reads newer data, skip this one.
        if (--reloadsQueued > 0) return null;
        return SongLibraryLoaded(await getAllSongs());
      });
    }

    out = StreamController<SongLibraryUpdate>(
      onListen: () {
        reload(); // the current library first
        changes = _changes.stream.listen(
          (change) => switch (change) {
            _Reload() => reload(),
            _Changed(:final songs) => enqueue(
              () async => SongLibrarySongsChanged(songs),
            ),
            _Removed(:final ids) => enqueue(
              () async => SongLibrarySongsRemoved(ids),
            ),
          },
        );
      },
      onCancel: () => changes?.cancel(),
    );
    return out.stream;
  }

  @override
  Future<bool> toggleFavorite(int songId) async {
    final song = await _isar.writeTxn(() async {
      final song = await _songs.get(songId);
      if (song == null) return null;
      song.isFavorite = !song.isFavorite;
      await _songs.put(song);
      return song;
    });
    if (song == null) return false;
    _changes.add(_Changed([song]));
    return song.isFavorite;
  }

  @override
  Future<void> setFavoriteMany(
    List<int> songIds, {
    required bool favorite,
  }) async {
    final changed = await _updateMany(songIds, (song) {
      if (song.isFavorite == favorite) return false;
      song.isFavorite = favorite;
      return true;
    });
    if (changed.isNotEmpty) _changes.add(_Changed(changed));
  }

  @override
  Future<void> removeSongs(List<int> songIds) async {
    if (songIds.isEmpty) return;
    await _isar.writeTxn(() => _forget(songIds));
    _changes.add(_Removed(songIds.toSet()));
  }

  /// Applies [change] to the existing songs among [songIds] and saves those
  /// it reports as changed. Returns the saved rows.
  Future<List<SongCollection>> _updateMany(
    List<int> songIds,
    bool Function(SongCollection song) change,
  ) async {
    if (songIds.isEmpty) return const [];
    return _isar.writeTxn(() async {
      final songs = await _songs.getAll(songIds);
      final changed = [
        for (final song in songs)
          if (song != null && change(song)) song,
      ];
      if (changed.isNotEmpty) await _songs.putAll(changed);
      return changed;
    });
  }

  @override
  Stream<bool> watchFavorite(int songId) => _songs
      .watchObject(songId, fireImmediately: true)
      .map((song) => song?.isFavorite ?? false)
      .distinct();

  @override
  Future<void> addListening(int songId, Duration listened) async {
    if (listened <= Duration.zero) return;
    await _isar.writeTxn(() async {
      final song = await _songs.get(songId);
      if (song == null) return;
      song.listenedMs = song.listenedOrEstimateMs + listened.inMilliseconds;
      await _songs.put(song);
    });
  }

  @override
  Future<void> recordPlay(int songId) async {
    final song = await _isar.writeTxn(() async {
      final song = await _songs.get(songId);
      if (song == null) return null;
      // Rows from before listening time was kept: their estimate (from the
      // plays so far) is fixed now, before this play is added.
      song
        ..listenedMs = song.listenedOrEstimateMs
        ..playCount += 1;
      await _songs.put(song);

      await _recent.put(RecentMusicCollection.played(songId));
      await _trimRecent();
      return song;
    });
    if (song != null) _changes.add(_Changed([song]));
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

/// What a committed write changed (see [MusicLocalStorageImpl.watchLibrary]).
sealed class _LibraryChange {
  const _LibraryChange();
}

/// Songs were added, removed or changed in bulk: re-read the library.
final class _Reload extends _LibraryChange {
  const _Reload();
}

/// These rows changed in place.
final class _Changed extends _LibraryChange {
  const _Changed(this.songs);

  final List<SongCollection> songs;
}

/// These songs left the visible library.
final class _Removed extends _LibraryChange {
  const _Removed(this.ids);

  final Set<int> ids;
}
