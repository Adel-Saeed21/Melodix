import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/library_changes.dart';
import 'package:melodix/features/music_library/domain/entities/library_search_results.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

/// In-memory search over the library, built from data the app already holds
/// (songs, albums, artists, playlists), so searching never reads the
/// database.
///
/// Lower-cased search text is prepared once per item. Matching is the same
/// as before: songs by title / artist / album, artists by name, albums by
/// title or artist, playlists by name; case-insensitive, trimmed.
class LibrarySearchIndex {
  const LibrarySearchIndex._({
    required this.songs,
    required this._songKeys,
    required this.albums,
    required this._albumKeys,
    required this.artists,
    required this._artistKeys,
    required this.playlists,
    required this._playlistKeys,
  });

  static const empty = LibrarySearchIndex._(
    songs: [],
    songKeys: [],
    albums: [],
    albumKeys: [],
    artists: [],
    artistKeys: [],
    playlists: [],
    playlistKeys: [],
  );

  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;

  final List<String> _songKeys;
  final List<String> _albumKeys;
  final List<String> _artistKeys;
  final List<String> _playlistKeys;

  /// Returns an index with the given parts replaced. Song keys are reused
  /// when only non-searchable fields changed (e.g. a favourite), so that
  /// update costs no string work.
  LibrarySearchIndex update({
    List<Song>? songs,
    List<Album>? albums,
    List<Artist>? artists,
    List<Playlist>? playlists,
  }) {
    final nextSongs = songs ?? this.songs;
    final reuseSongKeys =
        identical(nextSongs, this.songs) ||
        !catalogChanged(this.songs, nextSongs);
    final nextAlbums = albums ?? this.albums;
    final nextArtists = artists ?? this.artists;
    final nextPlaylists = playlists ?? this.playlists;
    return LibrarySearchIndex._(
      songs: nextSongs,
      songKeys: reuseSongKeys ? _songKeys : _keysForSongs(nextSongs),
      albums: nextAlbums,
      albumKeys: identical(nextAlbums, this.albums)
          ? _albumKeys
          : [
              for (final a in nextAlbums) _key([a.title, a.artist]),
            ],
      artists: nextArtists,
      artistKeys: identical(nextArtists, this.artists)
          ? _artistKeys
          : [for (final a in nextArtists) a.name.toLowerCase()],
      playlists: nextPlaylists,
      playlistKeys: identical(nextPlaylists, this.playlists)
          ? _playlistKeys
          : [for (final p in nextPlaylists) p.name.toLowerCase()],
    );
  }

  LibrarySearchResults search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return LibrarySearchResults.empty;
    return LibrarySearchResults(
      songs: _matching(songs, _songKeys, q),
      artists: _matching(artists, _artistKeys, q),
      albums: _matching(albums, _albumKeys, q),
      playlists: _matching(playlists, _playlistKeys, q),
    );
  }

  static List<T> _matching<T>(List<T> items, List<String> keys, String q) => [
    for (var i = 0; i < items.length; i++)
      if (keys[i].contains(q)) items[i],
  ];

  static List<String> _keysForSongs(List<Song> songs) => [
    for (final s in songs) _key([s.title, s.artist, s.album]),
  ];

  /// Fields joined with a line break, so a query (which never contains one)
  /// can't match across two fields.
  static String _key(List<String> fields) => fields.join('\n').toLowerCase();
}
