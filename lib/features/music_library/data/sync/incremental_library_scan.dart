import 'package:melodix/features/music_library/data/datasources/music_local_storage.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/features/music_library/data/models/local_song.dart';
import 'package:melodix/features/music_library/data/datasources/audio_library_delta_source.dart';
import 'package:melodix/features/music_library/data/datasources/music_file_filter.dart';
import 'package:melodix/core/utils/debug_counters.dart';

/// Sync strategy: apply only what changed in MediaStore since the saved
/// checkpoint (Android 11+).
///
/// Changed rows come from generations; deletions from comparing ids, since
/// generations never report deleted rows. Everything is saved in one
/// transaction with the new checkpoint.
class IncrementalLibraryScan {
  IncrementalLibraryScan({required this._deltaSource, required this._storage});

  final AudioLibraryDeltaSource _deltaSource;
  final SongSyncStorage _storage;

  /// Applies the changes since [since] (generation per volume) on MediaStore
  /// database [version].
  ///
  /// Returns null when MediaStore was rebuilt meanwhile: the caller must do
  /// a full scan. Query errors throw before anything is saved, so the old
  /// checkpoint stays and the next sync retries the same changes.
  ///
  /// [onSaving] is called once the changes were read, just before saving.
  Future<SongSyncResult?> run(
    Map<String, int> since,
    String version, {
    void Function()? onSaving,
  }) async {
    final changes = await _deltaSource.changesSince(since);
    if (changes.checkpoint.version != version) return null;
    _checkConsistent(changes);
    // ignore: invalid_use_of_visible_for_testing_member
    DebugCounters.hit('mediaStoreDelta');

    final (:upserts, :deleted) = _diff(
      changes,
      saved: await _storage.getAllSongIds(), // hidden songs included
    );
    onSaving?.call();
    return _storage.applyChanges(
      upserts: upserts,
      deletedIds: deleted,
      checkpoint: encodeSyncCheckpoint(
        changes.checkpoint,
        MusicFileFilter.rulesVersion,
      ),
    );
  }

  /// No ids while MediaStore counts rows means the ids query silently
  /// failed; applying it would delete the whole library.
  static void _checkConsistent(AudioLibraryChanges changes) {
    if (changes.allIds.isEmpty && changes.checkpoint.audioCount != 0) {
      throw MediaQueryException(
        'No ids returned but MediaStore counts '
        '${changes.checkpoint.audioCount}',
      );
    }
  }

  /// Songs to save and ids to remove, given the ids already [saved].
  static ({List<LocalSong> upserts, Set<int> deleted}) _diff(
    AudioLibraryChanges changes, {
    required Set<int> saved,
  }) {
    final upserts = <LocalSong>[];
    final deleted = <int>{};
    for (final record in changes.changed) {
      final song = record.toLocalSong();
      if (song != null) {
        upserts.add(song);
      } else if (saved.contains(record.id)) {
        deleted.add(record.id); // now excluded, e.g. moved to Recordings
      }
    }
    for (final id in saved) {
      if (!changes.allIds.contains(id)) deleted.add(id);
    }
    return (upserts: upserts, deleted: deleted);
  }
}
