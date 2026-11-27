import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/features/music_library/data/models/local_song.dart';

SongCollection songRow(
  int id, {
  String title = 'Song',
  String artist = 'Artist',
  String album = 'Album',
  int? albumId = 1,
  int durationMs = 60000,
  String? uri,
}) => SongCollection()
  ..id = id
  ..title = title
  ..artist = artist
  ..album = album
  ..albumId = albumId
  ..durationMs = durationMs
  ..path = '/storage/emulated/0/Music/$id.mp3'
  ..uri = uri
  ..sizeBytes = 1000
  ..addedAt = DateTime(2026);

LocalSong localSong(int id) => LocalSong(
  id: id,
  title: 'Song $id',
  artist: 'Artist',
  album: 'Album',
  albumId: 1,
  duration: const Duration(minutes: 1),
  path: '/music/$id.mp3',
  uri: 'content://media/external/audio/media/$id',
  size: 1000,
);
