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

  LibraryMetadataCollection();
}
