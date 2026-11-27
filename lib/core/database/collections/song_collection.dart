import 'package:isar_community/isar.dart';

part 'song_collection.g.dart';

/// A song from the device library, plus the user's data for it.
///
/// Scanned fields are overwritten on every library sync; user fields
/// ([isFavorite], [playCount]) are kept. Play history lives in
/// `RecentMusicCollection`.
@collection
class SongCollection {
  /// The MediaStore id, so re-scans update the same row.
  Id id = Isar.autoIncrement;

  // Scanned from the device
  @Index(caseSensitive: false)
  late String title;

  @Index(caseSensitive: false)
  late String artist;

  @Index(caseSensitive: false)
  late String album;

  @Index()
  int? albumId;

  late int durationMs;

  @Index(unique: true, replace: true)
  late String path;

  String? uri;
  late int sizeBytes;

  /// When the file was added to the device (from the scan). Null for files
  /// the device reported no date for, and for rows saved before this field
  /// existed until the next sync rewrites them.
  @Index()
  DateTime? dateAdded;

  // User data
  @Index()
  bool isFavorite = false;

  int playCount = 0;

  /// How long the song was really listened to, in milliseconds (paused,
  /// buffering and skipped time not included).
  ///
  /// Null on rows saved before this was tracked: their time is estimated
  /// as [playCount] × the song's length (see [listenedOrEstimateMs]), and
  /// that estimate is written here the first time it changes.
  int? listenedMs;

  /// [listenedMs], or the estimate for rows saved before it was tracked.
  @ignore
  int get listenedOrEstimateMs => listenedMs ?? playCount * durationMs;

  // An `isHidden` field used to live here (hiding songs was removed).
  // Isar ignores the values older versions stored, so songs they hid show
  // again with no migration. Don't reuse the name for something else.

  /// When the song first appeared in the library.
  late DateTime addedAt;

  SongCollection();

  /// True when every field read from the device matches [other], i.e. a
  /// re-scan found no changes to the file's metadata.
  bool hasSameScanData(SongCollection other) =>
      title == other.title &&
      artist == other.artist &&
      album == other.album &&
      albumId == other.albumId &&
      durationMs == other.durationMs &&
      path == other.path &&
      uri == other.uri &&
      sizeBytes == other.sizeBytes &&
      dateAdded == other.dateAdded;

  @ignore
  Duration get duration => Duration(milliseconds: durationMs);
}
