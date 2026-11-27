import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/song_collection.dart';

part 'song_history_collection.g.dart';

/// The listening history of a song that left the library (its file was
/// deleted or moved, or its storage removed), so the stats keep it.
///
/// If the song comes back with the same id (e.g. the SD card is put back),
/// this is merged into its new row and removed.
@collection
class SongHistoryCollection {
  /// The song's id (its MediaStore id).
  Id id = Isar.autoIncrement;

  late String title;
  late String artist;
  late int durationMs;
  int playCount = 0;
  int listenedMs = 0;
  bool isFavorite = false;

  /// When it left the library.
  late DateTime removedAt;

  SongHistoryCollection();

  /// What's worth keeping of [song]; null if it was never played,
  /// listened to or favourited.
  static SongHistoryCollection? of(SongCollection song, DateTime now) {
    final listened = song.listenedOrEstimateMs;
    if (song.playCount == 0 && listened == 0 && !song.isFavorite) return null;
    return SongHistoryCollection()
      ..id = song.id
      ..title = song.title
      ..artist = song.artist
      ..durationMs = song.durationMs
      ..playCount = song.playCount
      ..listenedMs = listened
      ..isFavorite = song.isFavorite
      ..removedAt = now;
  }

  /// Gives a returning song back its plays, time and favourite.
  void restoreInto(SongCollection song) {
    // The row's own time first: once the plays are added, an estimate
    // would count them again as full listens.
    final own = song.listenedOrEstimateMs;
    song
      ..listenedMs = own + listenedMs
      ..playCount += playCount
      ..isFavorite = song.isFavorite || isFavorite;
  }
}
