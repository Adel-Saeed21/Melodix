import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/get_albums_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_artists_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAlbums extends Mock implements GetAlbumsUseCase {}

class MockGetArtists extends Mock implements GetArtistsUseCase {}

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
    late MockGetAlbums getAlbums;
    late MockGetArtists getArtists;

    setUp(() {
      getAlbums = MockGetAlbums();
      getArtists = MockGetArtists();
    });

    test('loads albums and artists', () async {
      when(() => getAlbums(any()))
          .thenAnswer((_) async => const Right([_album]));
      when(() => getArtists(any()))
          .thenAnswer((_) async => const Right([_artist]));
      final cubit = LibraryCollectionsCubit(
        getAlbums: getAlbums,
        getArtists: getArtists,
      );

      await cubit.load();

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.albums, [_album]);
      expect(cubit.state.artists, [_artist]);
      await cubit.close();
    });

    test('reports a failure and keeps previous data', () async {
      when(() => getAlbums(any()))
          .thenAnswer((_) async => const Right([_album]));
      when(() => getArtists(any()))
          .thenAnswer((_) async => const Right([_artist]));
      final cubit = LibraryCollectionsCubit(
        getAlbums: getAlbums,
        getArtists: getArtists,
      );
      await cubit.load();

      when(() => getAlbums(any()))
          .thenAnswer((_) async => const Left(LibraryFailure('db')));
      await cubit.load();

      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.errorMessage, 'db');
      expect(cubit.state.albums, [_album]);
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
