import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/features/music_library/data/models/local_song.dart';

/// A scanned song as a database row.
extension LocalSongRow on LocalSong {
  /// The row for this song, keeping the user's data from [previous] (the
  /// row it replaces, if any).
  SongCollection toRow({SongCollection? previous}) => SongCollection()
    ..id = id
    ..title = title
    ..artist = artist
    ..album = album
    ..albumId = albumId
    ..durationMs = duration.inMilliseconds
    ..path = path
    ..uri = uri
    ..sizeBytes = size
    ..dateAdded = dateAdded
    ..isFavorite = previous?.isFavorite ?? false
    ..playCount = previous?.playCount ?? 0
    ..listenedMs = previous?.listenedMs
    ..addedAt = previous?.addedAt ?? DateTime.now();
}
