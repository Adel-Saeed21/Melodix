import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';

/// Builds album and artist lists from the saved songs.
class LibraryGrouping {
  LibraryGrouping._();

  static const String variousArtists = 'Various artists';

  /// Albums sorted by title. Songs are grouped by MediaStore album id, or by
  /// album name when the id is missing.
  static List<Album> albums(List<SongCollection> songs) {
    final groups = <String, List<SongCollection>>{};
    for (final song in songs) {
      final key = song.albumId != null
          ? 'id:${song.albumId}'
          : 'name:${song.album.toLowerCase()}';
      (groups[key] ??= []).add(song);
    }

    final albums = [
      for (final group in groups.values)
        Album(
          albumId: group.first.albumId,
          title: group.first.album,
          artist: _sharedArtist(group),
          songCount: group.length,
          duration: group.fold(Duration.zero, (sum, s) => sum + s.duration),
          artworkSongId: group.first.id,
        ),
    ];
    albums.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return albums;
  }

  /// Artists sorted by name (case-insensitive grouping).
  static List<Artist> artists(List<SongCollection> songs) {
    final groups = <String, List<SongCollection>>{};
    for (final song in songs) {
      (groups[song.artist.toLowerCase()] ??= []).add(song);
    }

    final artists = [
      for (final group in groups.values)
        Artist(
          name: group.first.artist,
          songCount: group.length,
          albumCount: group
              .map((s) => s.albumId?.toString() ?? s.album.toLowerCase())
              .toSet()
              .length,
          artworkSongId: group.first.id,
        ),
    ];
    artists.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return artists;
  }

  static String _sharedArtist(List<SongCollection> group) {
    final first = group.first.artist;
    final allSame = group.every(
      (s) => s.artist.toLowerCase() == first.toLowerCase(),
    );
    return allSame ? first : variousArtists;
  }
}
