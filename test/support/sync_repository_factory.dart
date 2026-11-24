import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/service/audio_library_delta_source.dart';
import 'package:melodix/features/music_library/data/repositories/library_sync_repository_impl.dart';
import 'package:melodix/features/music_library/data/sync/full_library_scan.dart';
import 'package:melodix/features/music_library/data/sync/incremental_library_scan.dart';

import 'fake_media_store.dart';

/// The production sync stack (orchestrator + both strategies) over a
/// simulated [device]. [deltaSource] replaces the device's own MediaStore
/// answers (e.g. a deliberately broken one).
LibrarySyncRepositoryImpl buildSyncRepository({
  required FakeMediaStore device,
  required MusicLocalStorage storage,
  AudioLibraryDeltaSource? deltaSource,
}) {
  final source = deltaSource ?? device;
  return LibrarySyncRepositoryImpl(
    permissionService: device,
    deltaSource: source,
    storage: storage,
    fullScan: FullLibraryScan(
      musicService: device,
      deltaSource: source,
      storage: storage,
    ),
    incrementalScan: IncrementalLibraryScan(
      deltaSource: source,
      storage: storage,
    ),
  );
}
