import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/entities/song_sort_order.dart';

Song _song(int id, String title, {DateTime? added, int plays = 0}) => Song(
  id: id,
  title: title,
  artist: 'Artist',
  album: 'Album',
  albumId: 1,
  duration: const Duration(minutes: 3),
  path: '/m/$id.mp3',
  playbackUri: Uri.parse('content://media/external/audio/media/$id'),
  isFavorite: false,
  playCount: plays,
  dateAdded: added,
);

void main() {
  final songs = [
    _song(1, 'beta', added: DateTime(2026, 1, 1), plays: 3),
    _song(2, 'Alpha', added: DateTime(2026, 6, 1), plays: 0),
    _song(3, 'gamma', added: null, plays: 9),
    _song(4, 'Delta', added: DateTime(2026, 6, 1), plays: 3),
  ];

  List<int> ids(List<Song> list) => [for (final s in list) s.id];

  test('A–Z is case-insensitive', () {
    expect(ids(sortSongs(songs, SongSortOrder.title)), [2, 1, 4, 3]);
  });

  test('recently added: newest first, ties by title, unknown dates last', () {
    expect(ids(sortSongs(songs, SongSortOrder.recentlyAdded)), [2, 4, 1, 3]);
  });

  test('most played: highest count first, ties by title', () {
    expect(ids(sortSongs(songs, SongSortOrder.mostPlayed)), [3, 1, 4, 2]);
  });

  test('returns a new list and leaves the input untouched', () {
    final input = [...songs];
    final sorted = sortSongs(input, SongSortOrder.title);
    expect(identical(sorted, input), isFalse);
    expect(ids(input), [1, 2, 3, 4]);
  });
}
