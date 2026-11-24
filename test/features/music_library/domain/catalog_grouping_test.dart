import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/music_library/domain/entities/catalog_grouping.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

Song _song(
  int id, {
  String title = 'Song',
  String artist = 'Artist',
  String album = 'Album',
  int? albumId = 1,
}) => Song(
  id: id,
  title: title,
  artist: artist,
  album: album,
  albumId: albumId,
  duration: const Duration(minutes: 1),
  path: '/music/$id.mp3',
  playbackUri: Uri.parse('content://media/external/audio/media/$id'),
  isFavorite: false,
  playCount: 0,
);

void main() {
  group('albums', () {
    test('groups by album id, totals duration, sorts by title', () {
      final albums = CatalogGrouping.albums([
        _song(1, album: 'Zeta', albumId: 10),
        _song(2, album: 'Alpha', albumId: 20),
        _song(3, album: 'Zeta', albumId: 10),
      ]);

      expect(albums.map((a) => a.title), ['Alpha', 'Zeta']);
      final zeta = albums.last;
      expect(zeta.albumId, 10);
      expect(zeta.songCount, 2);
      expect(zeta.duration, const Duration(minutes: 2));
      expect(zeta.artworkSongId, 1);
    });

    test('groups by name when the album id is missing', () {
      final albums = CatalogGrouping.albums([
        _song(1, album: 'Live', albumId: null),
        _song(2, album: 'live', albumId: null),
      ]);

      expect(albums, hasLength(1));
      expect(albums.single.albumId, isNull);
      expect(albums.single.songCount, 2);
    });

    test('marks albums with mixed artists as various artists', () {
      final albums = CatalogGrouping.albums([
        _song(1, artist: 'A'),
        _song(2, artist: 'B'),
      ]);

      expect(albums.single.artist, CatalogGrouping.variousArtists);
    });
  });

  test('artists group case-insensitively and count albums', () {
    final artists = CatalogGrouping.artists([
      _song(1, artist: 'Nova', album: 'One', albumId: 1),
      _song(2, artist: 'nova', album: 'Two', albumId: 2),
      _song(3, artist: 'Nova', album: 'One', albumId: 1),
      _song(4, artist: 'Alto', albumId: 3),
    ]);

    expect(artists.map((a) => a.name), ['Alto', 'Nova']);
    final nova = artists.last;
    expect(nova.songCount, 3);
    expect(nova.albumCount, 2);
  });

  test('an album id never collides with an album named like it', () {
    final artists = CatalogGrouping.artists([
      _song(1, album: 'X', albumId: 5),
      _song(2, album: '5', albumId: null),
    ]);

    expect(artists.single.albumCount, 2);
  });

  group('pages match the cards', () {
    final library = [
      _song(1, title: 'a', artist: 'Nova', album: 'Live', albumId: null),
      _song(2, title: 'b', artist: 'nova', album: 'live', albumId: null),
      _song(3, title: 'c', artist: 'Nova', album: 'Live', albumId: 9),
      _song(4, title: 'd', artist: 'Alto', album: 'Zeta', albumId: 2),
    ];

    test('every album page shows exactly the songs its card counts', () {
      for (final album in CatalogGrouping.albums(library)) {
        final songs = CatalogGrouping.albumSongs(library, album);
        expect(songs, hasLength(album.songCount), reason: album.title);
      }
      // Name-grouped albums match case-insensitively, but never an album
      // with an id.
      final byName = CatalogGrouping.albums(library)
          .firstWhere((a) => a.albumId == null);
      expect(CatalogGrouping.albumSongs(library, byName).map((s) => s.id), [
        1,
        2,
      ]);
    });

    test('every artist page shows exactly the songs its row counts', () {
      for (final artist in CatalogGrouping.artists(library)) {
        final songs = CatalogGrouping.artistSongs(library, artist.name);
        expect(songs, hasLength(artist.songCount), reason: artist.name);
      }
    });

    test('artist songs are sorted by album, then title', () {
      final songs = CatalogGrouping.artistSongs([
        _song(1, title: 'b', artist: 'Nova', album: 'Two', albumId: 2),
        _song(2, title: 'z', artist: 'Nova', album: 'One', albumId: 1),
        _song(3, title: 'a', artist: 'Nova', album: 'Two', albumId: 2),
      ], 'nova');

      expect(songs.map((s) => s.id), [2, 3, 1]);
    });

    test('albumOf / artistNamed find a song\'s album and artist', () {
      final album = CatalogGrouping.albumOf(library, library[1])!;
      expect(album.albumId, isNull);
      expect(album.songCount, 2);

      final artist = CatalogGrouping.artistNamed(library, 'NOVA')!;
      expect(artist.songCount, 3);
      expect(artist.albumCount, 2);
    });

    test('albumOf / artistNamed are null once the songs are gone', () {
      expect(CatalogGrouping.albumOf(const [], library.first), isNull);
      expect(CatalogGrouping.artistNamed(library, 'Nobody'), isNull);
    });
  });
}
