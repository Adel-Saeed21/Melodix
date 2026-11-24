import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/music_library/data/mappers/library_grouping.dart';
import 'package:melodix/features/music_library/domain/entities/catalog_grouping.dart';

import '../fixtures.dart';

void main() {
  group('albums', () {
    test('groups by album id, totals duration, sorts by title', () {
      final albums = LibraryGrouping.albums([
        songRow(1, album: 'Zeta', albumId: 10),
        songRow(2, album: 'Alpha', albumId: 20),
        songRow(3, album: 'Zeta', albumId: 10),
      ]);

      expect(albums.map((a) => a.title), ['Alpha', 'Zeta']);
      final zeta = albums.last;
      expect(zeta.albumId, 10);
      expect(zeta.songCount, 2);
      expect(zeta.duration, const Duration(minutes: 2));
      expect(zeta.artworkSongId, 1);
    });

    test('groups by name when the album id is missing', () {
      final albums = LibraryGrouping.albums([
        songRow(1, album: 'Live', albumId: null),
        songRow(2, album: 'live', albumId: null),
      ]);

      expect(albums, hasLength(1));
      expect(albums.single.albumId, isNull);
      expect(albums.single.songCount, 2);
    });

    test('marks albums with mixed artists as various artists', () {
      final albums = LibraryGrouping.albums([
        songRow(1, artist: 'A'),
        songRow(2, artist: 'B'),
      ]);

      expect(albums.single.artist, CatalogGrouping.variousArtists);
    });
  });

  test('artists group case-insensitively and count albums', () {
    final artists = LibraryGrouping.artists([
      songRow(1, artist: 'Nova', album: 'One', albumId: 1),
      songRow(2, artist: 'nova', album: 'Two', albumId: 2),
      songRow(3, artist: 'Nova', album: 'One', albumId: 1),
      songRow(4, artist: 'Alto', albumId: 3),
    ]);

    expect(artists.map((a) => a.name), ['Alto', 'Nova']);
    final nova = artists.last;
    expect(nova.songCount, 3);
    expect(nova.albumCount, 2);
  });
}
