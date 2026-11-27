import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/core/database/collections/recent_music_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/collections/song_history_collection.dart';

/// Songs leaving the library (their files deleted or moved, their storage
/// removed) and coming back: they go from the library, recents and
/// playlists, but their listening history is kept for the stats, and
/// given back if the song returns.
class RemovedSongs {
  const RemovedSongs(this._isar);

  final Isar _isar;

  IsarCollection<SongCollection> get _songs => _isar.songCollections;

  IsarCollection<SongHistoryCollection> get _history =>
      _isar.songHistoryCollections;

  IsarCollection<RecentMusicCollection> get _recent =>
      _isar.recentMusicCollections;

  IsarCollection<PlaylistCollection> get _playlists =>
      _isar.playlistCollections;

  /// Removes songs from the library, recents and playlists, keeping their
  /// listening history for the stats. Call inside a write transaction.
  Future<void> forget(List<int> songIds) async {
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
  Future<void> restoreInto(List<SongCollection> added) async {
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
}
