import 'package:isar_community/isar.dart';
import 'package:melodix/core/models/local_song.dart';

part 'song_collection.g.dart';

/// A song from the device library, plus the user's data for it.
///
/// Scanned fields are overwritten on every library sync; user fields
/// ([isFavorite], [playCount], [isHidden]) are kept. Play history lives in
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

  /// Hidden from the library by the user. The file stays on the device and
  /// the song is excluded from every list until unhidden.
  ///
  /// Rows saved before this field existed store null here, so queries must
  /// use `not().isHiddenEqualTo(true)` for visible songs, never
  /// `isHiddenEqualTo(false)` (which would skip those rows).
  @Index()
  bool isHidden = false;

  /// When the song first appeared in the library.
  late DateTime addedAt;

  SongCollection();

  /// Builds a row from a scanned song, keeping user data from [previous].
  factory SongCollection.fromLocalSong(
    LocalSong song, {
    SongCollection? previous,
  }) {
    return SongCollection()
      ..id = song.id
      ..title = song.title
      ..artist = song.artist
      ..album = song.album
      ..albumId = song.albumId
      ..durationMs = song.duration.inMilliseconds
      ..path = song.path
      ..uri = song.uri
      ..sizeBytes = song.size
      ..dateAdded = song.dateAdded
      ..isFavorite = previous?.isFavorite ?? false
      ..playCount = previous?.playCount ?? 0
      ..isHidden = previous?.isHidden ?? false
      ..addedAt = previous?.addedAt ?? DateTime.now();
  }

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

  LocalSong toLocalSong() => LocalSong(
    id: id,
    title: title,
    artist: artist,
    album: album,
    albumId: albumId,
    duration: duration,
    path: path,
    uri: uri,
    size: sizeBytes,
    dateAdded: dateAdded,
  );
}
