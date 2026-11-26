import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

/// Albums and artists built from the library's songs (in memory, no
/// database reads).
///
/// Every lookup goes through the same keys as the grouping, so an album's
/// page always shows exactly the songs its card counted.
abstract final class CatalogGrouping {
  static const String variousArtists = 'Various artists';

  /// Albums sorted by title. Songs are grouped by album id, or by album
  /// name (case-insensitive) when the id is missing.
  static List<Album> albums(List<Song> songs) {
    final groups = <String, List<Song>>{};
    for (final song in songs) {
      (groups[_albumKey(song.albumId, song.album)] ??= []).add(song);
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
    return _sortedBy(albums, (album) => album.title);
  }

  /// Artists sorted by name (case-insensitive grouping).
  static List<Artist> artists(List<Song> songs) {
    final groups = <String, List<Song>>{};
    for (final song in songs) {
      (groups[song.artist.toLowerCase()] ??= []).add(song);
    }

    final artists = [
      for (final group in groups.values)
        Artist(
          name: group.first.artist,
          songCount: group.length,
          albumCount: group
              .map((s) => _albumKey(s.albumId, s.album))
              .toSet()
              .length,
          artworkSongId: group.first.id,
        ),
    ];
    return _sortedBy(artists, (artist) => artist.name);
  }

  /// [album]'s songs, in the order of [songs] (the library's title order).
  static List<Song> albumSongs(List<Song> songs, Album album) {
    final key = _albumKey(album.albumId, album.title);
    return [
      for (final s in songs)
        if (_albumKey(s.albumId, s.album) == key) s,
    ];
  }

  /// The songs of the artist called [name] (case-insensitive), sorted by
  /// album, then title.
  static List<Song> artistSongs(List<Song> songs, String name) {
    final key = name.toLowerCase();
    return [
      for (final s in songs)
        if (s.artist.toLowerCase() == key) s,
    ]..sort((a, b) {
      final byAlbum = a.album.toLowerCase().compareTo(b.album.toLowerCase());
      if (byAlbum != 0) return byAlbum;
      final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
    });
  }

  /// The album [song] belongs to, or null if it's no longer in [songs].
  static Album? albumOf(List<Song> songs, Song song) {
    final key = _albumKey(song.albumId, song.album);
    final group = [
      for (final s in songs)
        if (_albumKey(s.albumId, s.album) == key) s,
    ];
    return group.isEmpty ? null : albums(group).single;
  }

  /// The artist called [name], or null if none of [songs] is theirs.
  static Artist? artistNamed(List<Song> songs, String name) {
    final group = artistSongs(songs, name);
    return group.isEmpty ? null : artists(group).single;
  }

  static String _albumKey(int? albumId, String title) =>
      albumId != null ? 'id:$albumId' : 'name:${title.toLowerCase()}';

  static String _sharedArtist(List<Song> group) {
    final first = group.first.artist;
    final key = first.toLowerCase();
    final allSame = group.every((s) => s.artist.toLowerCase() == key);
    return allSame ? first : variousArtists;
  }

  /// [items] sorted by [name], case-insensitively, lower-casing each name
  /// once (not on every comparison).
  static List<T> _sortedBy<T>(List<T> items, String Function(T) name) {
    final keyed = [for (final item in items) (item, name(item).toLowerCase())]
      ..sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final (item, _) in keyed) item];
  }
}
