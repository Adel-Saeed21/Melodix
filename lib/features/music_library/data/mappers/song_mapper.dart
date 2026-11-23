import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

/// Maps saved songs to domain [Song]s and decides how each one is played.
class SongMapper {
  const SongMapper({required this.isAndroid});

  final bool isAndroid;

  static const String _androidAudioContentBase =
      'content://media/external/audio/media';

  Song toEntity(SongCollection row) => Song(
    id: row.id,
    title: row.title,
    artist: row.artist,
    album: row.album,
    albumId: row.albumId,
    duration: row.duration,
    path: row.path,
    playbackUri: playbackUri(row),
    isFavorite: row.isFavorite,
    playCount: row.playCount,
    // The device's date if it reported one, else when the app first saw it.
    dateAdded: row.dateAdded ?? row.addedAt,
  );

  Uri playbackUri(SongCollection row) {
    final stored = row.uri;
    if (stored != null && stored.isNotEmpty) return Uri.parse(stored);
    if (isAndroid) return Uri.parse('$_androidAudioContentBase/${row.id}');
    return Uri.file(row.path);
  }
}
