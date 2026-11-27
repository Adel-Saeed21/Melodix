import 'package:melodix/features/music_library/data/datasources/audio_library_delta_source.dart';

/// Why a full scan is needed.
enum FullScanReason {
  /// The user asked for it (pull-to-refresh).
  forced,

  /// The device can't report generations (Android 10-, iOS, error).
  unsupported,

  /// No usable checkpoint saved yet (first sync, or unreadable).
  noCheckpoint,

  /// The music filter rules changed since the checkpoint was saved.
  rulesChanged,

  /// MediaStore rebuilt its database: old generations mean nothing.
  mediaStoreRebuilt,
}

sealed class LibrarySyncPlan {
  const LibrarySyncPlan();
}

/// Nothing changed on the device since the saved checkpoint.
class SkipSync extends LibrarySyncPlan {
  const SkipSync();
}

/// Read only rows changed after [since] (per volume) plus all ids.
class IncrementalSync extends LibrarySyncPlan {
  const IncrementalSync({required this.since, required this.version});

  /// Last synced generation per volume present now. A newly inserted volume
  /// gets 0 (read entirely); a removed volume isn't listed (its rows drop
  /// out of the id list and are deleted).
  final Map<String, int> since;

  /// The MediaStore version the generations belong to.
  final String version;
}

class FullSync extends LibrarySyncPlan {
  const FullSync(this.reason);

  final FullScanReason reason;
}

/// Chooses how to bring the library in line with the device.
LibrarySyncPlan planLibrarySync({
  required bool force,
  required MediaStoreCheckpoint? current,
  required ({MediaStoreCheckpoint checkpoint, int rulesVersion})? saved,
  required int rulesVersion,
}) {
  if (force) return const FullSync(FullScanReason.forced);
  if (current == null) return const FullSync(FullScanReason.unsupported);
  if (saved == null) return const FullSync(FullScanReason.noCheckpoint);
  if (saved.rulesVersion != rulesVersion) {
    return const FullSync(FullScanReason.rulesChanged);
  }
  if (saved.checkpoint.version != current.version) {
    return const FullSync(FullScanReason.mediaStoreRebuilt);
  }
  if (saved.checkpoint == current) return const SkipSync();
  return IncrementalSync(
    version: current.version,
    since: {
      // Each volume against its own saved generation; never shared.
      for (final volume in current.generations.keys)
        volume: saved.checkpoint.generations[volume] ?? 0,
    },
  );
}
