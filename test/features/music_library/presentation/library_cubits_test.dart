import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/build_library_catalog_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:mocktail/mocktail.dart';

const _album = Album(
  albumId: 1,
  title: 'Album',
  artist: 'Artist',
  songCount: 2,
  duration: Duration(minutes: 6),
  artworkSongId: 1,
);
const _artist = Artist(
  name: 'Artist',
  songCount: 2,
  albumCount: 1,
  artworkSongId: 1,
);

void main() {
  setUpAll(() => registerFallbackValue(const NoParams()));

  group('LibraryCollectionsCubit', () {
    Song song(
      int id, {
      String album = 'Album',
      int? albumId = 1,
      int playCount = 0,
      bool isFavorite = false,
    }) => Song(
      id: id,
      title: 'Song $id',
      artist: 'Artist',
      album: album,
      albumId: albumId,
      duration: const Duration(minutes: 3),
      path: '/m/$id.mp3',
      playbackUri: Uri.parse('content://media/external/audio/media/$id'),
      isFavorite: isFavorite,
      playCount: playCount,
    );

    test('builds albums and artists from the songs it is given', () async {
      final cubit = LibraryCollectionsCubit(
        buildCatalog: const BuildLibraryCatalogUseCase(),
      );

      await cubit.onLibraryChanged([song(1), song(2)]);

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.albums, [_album]);
      expect(cubit.state.artists, [_artist]);
      await cubit.close();
    });

    test('regroups only when the catalog changed', () async {
      final cubit = LibraryCollectionsCubit(
        buildCatalog: const BuildLibraryCatalogUseCase(),
      );
      await cubit.onLibraryChanged([song(1), song(2)]);
      final built = cubit.state;

      // A play count / favourite change: same albums, no new state.
      await cubit.onLibraryChanged([
        song(1, playCount: 3, isFavorite: true),
        song(2),
      ]);
      expect(identical(cubit.state, built), isTrue);

      // A song moved to another album: rebuilt.
      await cubit.onLibraryChanged([song(1), song(2, album: 'B', albumId: 2)]);
      expect(cubit.state.albums, hasLength(2));
      await cubit.close();
    });
  });

  group('SongListCubit', () {
    final song = Song(
      id: 1,
      title: 'Song',
      artist: 'Artist',
      album: 'Album',
      albumId: 1,
      duration: const Duration(minutes: 3),
      path: '/m/1.mp3',
      playbackUri: Uri.parse('content://media/external/audio/media/1'),
      isFavorite: false,
      playCount: 0,
    );

    test('emits loaded songs', () async {
      final cubit = SongListCubit(() async => Right([song]));
      await cubit.load();

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.songs, [song]);
      await cubit.close();
    });

    test('emits failure', () async {
      final cubit = SongListCubit(
        () async => const Left(LibraryFailure('nope')),
      );
      await cubit.load();

      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.errorMessage, 'nope');
      await cubit.close();
    });
  });
}
