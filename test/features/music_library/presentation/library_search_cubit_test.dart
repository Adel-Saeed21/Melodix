import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/utils/debug_counters.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';

Song _song(int id, String title, {bool favourite = false}) => Song(
  id: id,
  title: title,
  artist: 'Artist',
  album: 'Album',
  albumId: 1,
  duration: const Duration(minutes: 3),
  path: '/m/$id.mp3',
  playbackUri: Uri.parse('content://x/$id'),
  isFavorite: favourite,
  playCount: 0,
);

void main() {
  LibrarySearchCubit build() =>
      LibrarySearchCubit(debounce: const Duration(milliseconds: 20))
        ..updateSources(
          songs: [_song(1, 'Nova'), _song(2, 'Rain')],
          artists: const [
            Artist(name: 'Nova', songCount: 1, albumCount: 1, artworkSongId: 1),
          ],
        );

  Future<void> wait([int ms = 40]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  test('debounces typing into one search for the final text', () async {
    final cubit = build();
    DebugCounters.reset();

    cubit
      ..queryChanged('n')
      ..queryChanged('no')
      ..queryChanged(' nov ');
    expect(cubit.state.isLoading, isTrue);
    expect(cubit.state.query, 'nov');
    await wait();

    expect(DebugCounters.of('searchRun'), 1);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.results.songs.single.title, 'Nova');
    expect(cubit.state.results.artists.single.name, 'Nova');
    await cubit.close();
  });

  test('clearing resets to the empty prompt', () async {
    final cubit = build()..queryChanged('nova');
    await wait();

    cubit.clear();

    expect(cubit.state.hasQuery, isFalse);
    expect(cubit.state.results.isEmpty, isTrue);
    await cubit.close();
  });

  test('library updates refresh open results (e.g. a favourite)', () async {
    final cubit = build()..queryChanged('nova');
    await wait();
    expect(cubit.state.results.songs.single.isFavorite, isFalse);

    cubit.updateSources(
      songs: [_song(1, 'Nova', favourite: true), _song(2, 'Rain')],
    );

    expect(cubit.state.results.songs.single.isFavorite, isTrue);
    await cubit.close();
  });

  test('a hidden song disappears from open results', () async {
    final cubit = build()..queryChanged('rain');
    await wait();
    expect(cubit.state.results.songs, hasLength(1));

    cubit.updateSources(songs: [_song(1, 'Nova')]);

    expect(cubit.state.results.songs, isEmpty);
    await cubit.close();
  });
}
