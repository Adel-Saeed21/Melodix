import 'package:melodix/core/models/local_song.dart';
import 'package:melodix/core/service/music_file_filter.dart';

/// Turns one audio file's MediaStore fields into a [LocalSong], applying the
/// music-only rules ([MusicFileFilter]). Returns null for files that aren't
/// music (recordings, ringtones, …).
///
/// Shared by the full scan and the incremental scan, so both produce exactly
/// the same songs for the same file.
LocalSong? buildMusicLocalSong({
  required int id,
  required String path,
  required String? uri,
  String? title,
  String? artist,
  String? album,
  int? albumId,
  int? durationMs,
  int size = 0,
  int? dateAddedSeconds,
  bool? isMusic,
  bool? isAlarm,
  bool? isNotification,
  bool? isRingtone,
  bool? isPodcast,
  bool? isAudioBook,
}) {
  final keep = MusicFileFilter.isMusic(
    path: path,
    durationMs: durationMs,
    isMusic: isMusic,
    isAlarm: isAlarm,
    isNotification: isNotification,
    isRingtone: isRingtone,
    isPodcast: isPodcast,
    isAudioBook: isAudioBook,
  );
  if (!keep) return null;

  return LocalSong(
    id: id,
    title: _clean(title, _fileNameWithoutExtension(path)),
    artist: _clean(artist, unknownArtist),
    album: _clean(album, unknownAlbum),
    albumId: albumId,
    duration: Duration(milliseconds: durationMs ?? 0),
    path: path,
    uri: uri,
    size: size,
    dateAdded: dateAddedSeconds == null || dateAddedSeconds <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(dateAddedSeconds * 1000),
  );
}

/// Saved in place of a missing artist / album tag.
const String unknownArtist = 'Unknown artist';
const String unknownAlbum = 'Unknown album';

const String _unknown = '<unknown>';

String _clean(String? value, String fallback) =>
    (value == null || value.isEmpty || value == _unknown) ? fallback : value;

/// Same as the full scan's "display name without extension": the file name
/// from the path, without its extension.
String _fileNameWithoutExtension(String path) {
  final name = path.split('/').last;
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}
