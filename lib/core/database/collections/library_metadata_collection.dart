import 'package:isar_community/isar.dart';

part 'library_metadata_collection.g.dart';

/// Bookkeeping about the local media library. Single row ([singletonId]).
@collection
class LibraryMetadataCollection {
  static const int singletonId = 0;

  Id id = singletonId;

  /// When the music library was last fully synced with the device.
  /// Null until the first successful scan.
  DateTime? lastSongSyncAt;

  /// Where MediaStore stood at the last successful sync (version,
  /// per-volume generations, audio count, music filter rules version), as
  /// JSON. Saved in the same transaction as the songs it describes. Null
  /// until a sync saved one, or on devices without generations.
  String? songSyncCheckpoint;

  /// When the video library was last fully synced with the device.
  DateTime? lastVideoSyncAt;

  /// What the device's videos looked like at the last full video sync (how
  /// many, and the most recently changed one), saved in the same
  /// transaction as the videos. The same answer later means nothing
  /// changed, so the full scan is skipped. Null until a sync saved one.
  String? videoSyncCheckpoint;

  LibraryMetadataCollection();
}
