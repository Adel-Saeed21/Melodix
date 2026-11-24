import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/library_search_index.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

Song song(
  int id,
  String title, {
  String artist = 'Aria',
  String album = 'Dawn',
}) => Song(
  id: id,
  title: title,
  artist: artist,
  album: album,
  albumId: id,
  duration: const Duration(minutes: 3),
  path: '/m/$id.mp3',
  playbackUri: Uri.parse('content://x/$id'),
  isFavorite: false,
  playCount: 0,
);

void main() {
  final songs = [
    song(1, 'Nova Lights'),
    song(2, 'Rain', artist: 'Nova', album: 'Clouds'),
    song(3, 'Sun', album: 'Supernova'),
    song(4, 'Other', artist: 'Zed', album: 'Misc'),
  ];
  const artists = [
    Artist(name: 'Aria', songCount: 2, albumCount: 2, artworkSongId: 1),
    Artist(name: 'Nova', songCount: 1, albumCount: 1, artworkSongId: 2),
  ];
  const albums = [
    Album(
      albumId: 2,
      title: 'Clouds',
      artist: 'Nova',
      songCount: 1,
      duration: Duration.zero,
      artworkSongId: 2,
    ),
    Album(
      albumId: 3,
      title: 'Supernova',
      artist: 'Aria',
      songCount: 1,
      duration: Duration.zero,
      artworkSongId: 3,
    ),
    Album(
      albumId: 4,
      title: 'Misc',
      artist: 'Zed',
      songCount: 1,
      duration: Duration.zero,
      artworkSongId: 4,
    ),
  ];
  const playlists = [
    Playlist(
      id: 7,
      name: 'nova nights',
      songCount: 0,
      isFavorite: false,
      artworkSongId: null,
    ),
    Playlist(
      id: 8,
      name: 'Gym',
      songCount: 0,
      isFavorite: false,
      artworkSongId: null,
    ),
  ];
  final index = LibrarySearchIndex.empty.update(
    songs: songs,
    albums: albums,
    artists: artists,
    playlists: playlists,
  );

  test('matches every kind case-insensitively (same rules as before)', () {
    final results = index.search(' NOVA ');

    expect(results.songs.map((s) => s.id), [1, 2, 3]); // title, artist, album
    expect(results.artists.map((a) => a.name), ['Nova']);
    expect(results.albums.map((a) => a.title), ['Clouds', 'Supernova']);
    expect(results.playlists.map((p) => p.name), ['nova nights']);
  });

  test('an empty query returns nothing', () {
    expect(index.search('   ').isEmpty, isTrue);
  });

  test('a query never matches across two fields', () {
    // "lights" + "aria" are separate fields of song 1.
    expect(index.search('lightsaria').songs, isEmpty);
    expect(index.search('lights aria').songs, isEmpty);
  });

  test('favourite changes swap in new songs without re-indexing', () {
    final favourited = [
      Song(
        id: 1,
        title: 'Nova Lights',
        artist: 'Aria',
        album: 'Dawn',
        albumId: 1,
        duration: const Duration(minutes: 3),
        path: '/m/1.mp3',
        playbackUri: Uri.parse('content://x/1'),
        isFavorite: true,
        playCount: 0,
      ),
      ...songs.skip(1),
    ];

    final updated = index.update(songs: favourited);

    expect(updated.search('lights').songs.single.isFavorite, isTrue);
  });

  test('catalog changes are re-indexed', () {
    final renamed = [song(1, 'Midnight'), ...songs.skip(1)];

    final updated = index.update(songs: renamed);

    expect(updated.search('lights').songs, isEmpty);
    expect(updated.search('midnight').songs.single.id, 1);
  });
}
