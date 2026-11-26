import 'package:melodix/core/preferences/library_filter.dart';
import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/recent_music_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';

/// The "recently played" music list.
///
/// Entries are added by `MusicLocalStorage.recordPlay`, which also updates
/// the song's play count in the same transaction.
abstract interface class RecentMusicLocalStorage {
  /// Most entries kept; older ones are dropped.
  static const int maxEntries = 50;

  /// Recently played songs, newest first, skipping songs no longer on the
  /// device.
  Future<List<SongCollection>> getRecentSongs({int limit = maxEntries});

  /// Emits the recent songs (newest first) now and whenever the list changes.
  Stream<List<SongCollection>> watchRecentSongs({int limit = maxEntries});

  Future<void> removeFromRecent(int songId);

  Future<void> clearRecent();
}

class RecentMusicLocalStorageImpl implements RecentMusicLocalStorage {
  RecentMusicLocalStorageImpl(this._isar, {LibraryFilter Function()? filter})
    : _filter = filter ?? (() => LibraryFilter.defaults);

  final Isar _isar;

  /// What the library shows (Settings › Music filters); read each time.
  final LibraryFilter Function() _filter;

  bool _keeps(SongCollection s) =>
      _filter().keeps(path: s.path, durationMs: s.durationMs);

  IsarCollection<RecentMusicCollection> get _recent =>
      _isar.recentMusicCollections;

  @override
  Future<List<SongCollection>> getRecentSongs({
    int limit = RecentMusicLocalStorage.maxEntries,
  }) async {
    final entries = await _recent
        .where()
        .sortByPlayedAtDesc()
        .limit(limit)
        .findAll();
    if (entries.isEmpty) return const [];
    final songs = await _isar.songCollections.getAll([
      for (final e in entries) e.songId,
    ]);
    return songs
        .whereType<SongCollection>()
        .where(_keeps)
        .toList(growable: false);
  }

  @override
  Stream<List<SongCollection>> watchRecentSongs({
    int limit = RecentMusicLocalStorage.maxEntries,
  }) {
    return _recent
        .watchLazy(fireImmediately: true)
        .asyncMap((_) => getRecentSongs(limit: limit));
  }

  @override
  Future<void> removeFromRecent(int songId) =>
      _isar.writeTxn(() => _recent.delete(songId));

  @override
  Future<void> clearRecent() => _isar.writeTxn(() => _recent.clear());
}
