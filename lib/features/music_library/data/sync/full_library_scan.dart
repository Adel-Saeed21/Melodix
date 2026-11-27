import 'package:melodix/features/music_library/data/datasources/music_local_storage.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/features/music_library/data/models/local_song.dart';
import 'package:melodix/features/music_library/data/datasources/audio_library_delta_source.dart';
import 'package:melodix/features/music_library/data/datasources/music_file_filter.dart';
import 'package:melodix/features/music_library/data/datasources/music_service.dart';
import 'package:melodix/core/utils/debug_counters.dart';

/// Sync strategy: read every audio file and replace the saved library with
/// the result (in one transaction, with the new checkpoint).
///
/// Data safety: on Android the native scan is used, which reports failures
/// instead of returning an empty list. Elsewhere [MusicService] reads the
/// files; it can't tell "empty" from "failed", so an empty answer never
/// wipes a non-empty library unless a native count of 0 confirms it.
class FullLibraryScan {
  FullLibraryScan({
    required this._musicService,
    required this._deltaSource,
    required this._storage,
  });

  final MusicService _musicService;
  final AudioLibraryDeltaSource _deltaSource;
  final SongSyncStorage _storage;

  /// Scans and saves. [current] is the checkpoint read before planning
  /// (null on devices without generations: the next sync scans again).
  ///
  /// Throws [MediaPermissionException] / [MediaQueryException] before
  /// anything is saved if the device can't be read completely.
  ///
  /// [onSaving] is called once everything was read, just before saving.
  Future<SongSyncResult> run(
    MediaStoreCheckpoint? current, {
    void Function()? onSaving,
  }) async {
    // ignore: invalid_use_of_visible_for_testing_member
    DebugCounters.hit('mediaStoreScan');
    final scan = await _deltaSource.fullScan();
    final (songs, checkpoint) = scan != null
        ? _fromNativeScan(scan)
        : await _fromMusicService(current);
    onSaving?.call();
    return _storage.syncSongs(
      songs,
      checkpoint: checkpoint == null
          ? null
          : encodeSyncCheckpoint(checkpoint, MusicFileFilter.rulesVersion),
    );
  }

  (List<LocalSong>, MediaStoreCheckpoint?) _fromNativeScan(AudioFullScan scan) {
    final checkpoint = scan.checkpoint;
    if (scan.records.isEmpty && (checkpoint?.audioCount ?? 0) != 0) {
      throw MediaQueryException(
        'Scan returned no rows but MediaStore counts '
        '${checkpoint!.audioCount}',
      );
    }
    return ([for (final r in scan.records) ?r.toLocalSong()], checkpoint);
  }

  Future<(List<LocalSong>, MediaStoreCheckpoint?)> _fromMusicService(
    MediaStoreCheckpoint? current,
  ) async {
    final songs = await _musicService.getAllSongs();
    final confirmedEmpty = current?.audioCount == 0;
    if (songs.isEmpty &&
        !confirmedEmpty &&
        (await _storage.getAllSongIds()).isNotEmpty) {
      throw const MediaQueryException(
        'Scan found no songs; not confirmed, library kept',
      );
    }
    return (songs, current);
  }
}
