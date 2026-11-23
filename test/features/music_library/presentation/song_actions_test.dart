import 'package:dartz/dartz.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/add_songs_to_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/create_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_artist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_playlists_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_album_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/remove_song_from_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/set_song_hidden_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/set_songs_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/set_songs_hidden_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/delete_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_song_favorite_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_actions_scope.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_options_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_tile.dart';
import 'package:mocktail/mocktail.dart';

class MockToggleFavorite extends Mock implements ToggleSongFavoriteUseCase {}

class MockSetHidden extends Mock implements SetSongHiddenUseCase {}

class MockGetPlaylists extends Mock implements GetPlaylistsUseCase {}

class MockCreatePlaylist extends Mock implements CreatePlaylistUseCase {}

class MockAddToPlaylist extends Mock implements AddSongsToPlaylistUseCase {}

class MockGetAlbum extends Mock implements GetSongAlbumUseCase {}

class MockGetArtist extends Mock implements GetArtistUseCase {}

class MockGetArtwork extends Mock implements GetSongArtworkUseCase {}

class MockRemoveFromPlaylist extends Mock
    implements RemoveSongFromPlaylistUseCase {}

class MockSetSongsHidden extends Mock implements SetSongsHiddenUseCase {}

class MockSetSongsFavorite extends Mock implements SetSongsFavoriteUseCase {}

class MockDeleteSongs extends Mock implements DeleteSongsUseCase {}

Song _song({bool favorite = false}) => Song(
  id: 7,
  title: 'Track',
  artist: 'Artist',
  album: 'Album',
  albumId: 1,
  duration: const Duration(minutes: 3),
  path: '/m/7.mp3',
  playbackUri: Uri.parse('content://media/external/audio/media/7'),
  isFavorite: favorite,
  playCount: 0,
);

const _playlist = Playlist(
  id: 3,
  name: 'Road trip',
  songCount: 4,
  isFavorite: false,
  artworkSongId: 7,
);

void main() {
  late MockToggleFavorite toggleFavorite;
  late MockSetHidden setHidden;
  late MockGetPlaylists getPlaylists;
  late MockCreatePlaylist createPlaylist;
  late MockAddToPlaylist addToPlaylist;
  late MockGetAlbum getAlbum;
  late MockGetArtist getArtist;
  late MockRemoveFromPlaylist removeFromPlaylist;
  late MockSetSongsHidden setSongsHidden;
  late MockSetSongsFavorite setSongsFavorite;
  late MockDeleteSongs deleteSongs;

  setUpAll(() {
    registerFallbackValue(const SetSongHiddenParams(0, hidden: true));
    registerFallbackValue(const AddSongsToPlaylistParams(0, []));
    registerFallbackValue(const CreatePlaylistParams(''));
    registerFallbackValue(const NoParams());
    registerFallbackValue(const SongArtworkParams(0));
    registerFallbackValue(_song());
    registerFallbackValue(const RemoveSongFromPlaylistParams(0, 0));
    registerFallbackValue(const SetSongsHiddenParams([], hidden: true));
    registerFallbackValue(const SetSongsFavoriteParams([], favorite: true));
    registerFallbackValue(<int>[]);
  });

  setUp(() {
    toggleFavorite = MockToggleFavorite();
    setHidden = MockSetHidden();
    getPlaylists = MockGetPlaylists();
    createPlaylist = MockCreatePlaylist();
    addToPlaylist = MockAddToPlaylist();
    getAlbum = MockGetAlbum();
    getArtist = MockGetArtist();
    removeFromPlaylist = MockRemoveFromPlaylist();
    setSongsHidden = MockSetSongsHidden();
    setSongsFavorite = MockSetSongsFavorite();
    deleteSongs = MockDeleteSongs();
    when(() => deleteSongs.isSupported).thenReturn(true);
  });

  SongActionsCubit buildCubit() => SongActionsCubit(
    toggleFavorite: toggleFavorite,
    setHidden: setHidden,
    getPlaylists: getPlaylists,
    createPlaylist: createPlaylist,
    addToPlaylist: addToPlaylist,
    getAlbum: getAlbum,
    getArtist: getArtist,
    removeFromPlaylist: removeFromPlaylist,
    setSongsHidden: setSongsHidden,
    setSongsFavorite: setSongsFavorite,
    deleteSongs: deleteSongs,
  );

  group('SongActionsCubit', () {
    test('toggleFavorite reports the new state', () async {
      when(() => toggleFavorite(7)).thenAnswer((_) async => const Right(true));
      final cubit = buildCubit();

      await cubit.toggleFavorite(_song());

      expect(cubit.state?.message, 'Added to favourites');
      await cubit.close();
    });

    test('hide offers undo, which unhides silently', () async {
      when(() => setHidden(any())).thenAnswer((_) async => const Right(unit));
      when(() => setSongsHidden(any()))
          .thenAnswer((_) async => const Right(unit));
      final cubit = buildCubit();

      await cubit.hide(_song());
      expect(cubit.state?.message, 'Hidden from library');
      expect(cubit.state?.undoHideIds, [7]);

      final before = cubit.state;
      await cubit.unhideMany([7], silent: true);
      expect(cubit.state, before);
      final params =
          verify(() => setSongsHidden(captureAny())).captured.single
              as SetSongsHiddenParams;
      expect(params.songIds, [7]);
      expect(params.hidden, isFalse);
      await cubit.close();
    });

    test('addToPlaylist reports added vs already there', () async {
      when(() => addToPlaylist(any())).thenAnswer((_) async => const Right(1));
      final cubit = buildCubit();
      await cubit.addToPlaylist(_song(), _playlist);
      expect(cubit.state?.message, 'Added to "Road trip"');

      when(() => addToPlaylist(any())).thenAnswer((_) async => const Right(0));
      await cubit.addToPlaylist(_song(), _playlist);
      expect(cubit.state?.message, 'Already in "Road trip"');
      await cubit.close();
    });

    test('createPlaylistWith creates it with the song', () async {
      when(() => createPlaylist(any())).thenAnswer((_) async => const Right(9));
      final cubit = buildCubit();

      await cubit.createPlaylistWith(_song(), '  Chill  ');

      final params =
          verify(() => createPlaylist(captureAny())).captured.single
              as CreatePlaylistParams;
      expect(params.name, 'Chill');
      expect(params.songIds, [7]);
      expect(cubit.state?.message, 'Added to "Chill"');
      await cubit.close();
    });

    test('failures surface their message', () async {
      when(() => toggleFavorite(7))
          .thenAnswer((_) async => const Left(LibraryFailure('Nope')));
      final cubit = buildCubit();

      await cubit.toggleFavorite(_song());

      expect(cubit.state?.message, 'Nope');
      await cubit.close();
    });

    test('removeFromPlaylist names the playlist', () async {
      when(() => removeFromPlaylist(any()))
          .thenAnswer((_) async => const Right(unit));
      final cubit = buildCubit();

      await cubit.removeFromPlaylist(_song(), _playlist);

      final params =
          verify(() => removeFromPlaylist(captureAny())).captured.single
              as RemoveSongFromPlaylistParams;
      expect(params.playlistId, 3);
      expect(params.songId, 7);
      expect(cubit.state?.message, 'Removed from "Road trip"');
      await cubit.close();
    });

    group('bulk', () {
      final songs = [_song(), _song(favorite: true)];

      test('favoriteMany favourites unless all already are', () async {
        when(() => setSongsFavorite(any()))
            .thenAnswer((_) async => const Right(unit));
        final cubit = buildCubit();

        expect(await cubit.favoriteMany(songs), isTrue);
        var params =
            verify(() => setSongsFavorite(captureAny())).captured.single
                as SetSongsFavoriteParams;
        expect(params.favorite, isTrue);
        expect(cubit.state?.message, 'Added 2 songs to favourites');

        await cubit.favoriteMany([
          _song(favorite: true),
          _song(favorite: true),
        ]);
        params =
            verify(() => setSongsFavorite(captureAny())).captured.single
                as SetSongsFavoriteParams;
        expect(params.favorite, isFalse);
        await cubit.close();
      });

      test('hideMany offers undo for all of them', () async {
        when(() => setSongsHidden(any()))
            .thenAnswer((_) async => const Right(unit));
        final cubit = buildCubit();

        expect(await cubit.hideMany(songs), isTrue);

        expect(cubit.state?.message, '2 songs hidden');
        expect(cubit.state?.undoHideIds, [7, 7]);
        await cubit.close();
      });

      test('addManyToPlaylist reports the count', () async {
        when(() => addToPlaylist(any()))
            .thenAnswer((_) async => const Right(2));
        final cubit = buildCubit();

        expect(await cubit.addManyToPlaylist(songs, _playlist), isTrue);

        expect(cubit.state?.message, 'Added 2 songs to "Road trip"');
        await cubit.close();
      });

      test(
        'deleteMany reports deleted songs, or nothing when declined',
        () async {
          final cubit = buildCubit();
          when(() => deleteSongs(any()))
              .thenAnswer((_) async => const Right(2));
          expect(await cubit.deleteMany(songs), isTrue);
          expect(cubit.state?.message, 'Deleted 2 songs');

          when(() => deleteSongs(any()))
              .thenAnswer((_) async => const Right(0));
          expect(await cubit.deleteMany(songs), isFalse);
          expect(cubit.state?.message, 'No songs were deleted');
          expect(cubit.canDeleteSongs, isTrue);
          await cubit.close();
        },
      );
    });

    test('albumFor reports when the album is missing', () async {
      when(() => getAlbum(any())).thenAnswer((_) async => const Right(null));
      final cubit = buildCubit();

      expect(await cubit.albumFor(_song()), isNull);
      expect(cubit.state?.message, 'This song is no longer in your library');
      await cubit.close();
    });
  });

  group('SongOptionsButton', () {
    setUp(() async {
      await getIt.reset();
      final artwork = MockGetArtwork();
      when(() => artwork(any())).thenAnswer((_) async => null);
      getIt
        ..registerSingleton<GetSongArtworkUseCase>(artwork)
        ..registerFactory<SongActionsCubit>(buildCubit);
    });

    tearDown(() => getIt.reset());

    Future<void> pumpTile(
      WidgetTester tester,
      Song song, {
      Playlist? playlist,
    }) async {
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: SongActionsScope(
                child: SongTile(
                  song: song,
                  trailing: SongOptionsButton(song: song, playlist: playlist),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Song options'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the options, with queue items disabled', (tester) async {
      await pumpTile(tester, _song());

      for (final label in [
        'Play next',
        'Add to queue',
        'Add to favourites',
        'Add to playlist',
        'Go to album',
        'Go to artist',
        'Hide from library',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      final playNext = tester.widget<PopupMenuItem<Object?>>(
        find.ancestor(
          of: find.text('Play next'),
          matching: find.byWidgetPredicate((w) => w is PopupMenuItem),
        ),
      );
      expect(playNext.enabled, isFalse);
    });

    testWidgets('offers removal for a favourite song', (tester) async {
      await pumpTile(tester, _song(favorite: true));

      expect(find.text('Remove from favourites'), findsOneWidget);
      expect(find.text('Add to favourites'), findsNothing);
    });

    testWidgets('favourite option toggles and shows feedback', (tester) async {
      when(() => toggleFavorite(7)).thenAnswer((_) async => const Right(true));
      await pumpTile(tester, _song());

      await tester.tap(find.text('Add to favourites'));
      await tester.pumpAndSettle();

      verify(() => toggleFavorite(7)).called(1);
      expect(find.text('Added to favourites'), findsOneWidget);
    });

    testWidgets('hiding shows a snackbar with undo', (tester) async {
      when(() => setHidden(any())).thenAnswer((_) async => const Right(unit));
      when(() => setSongsHidden(any()))
          .thenAnswer((_) async => const Right(unit));
      await pumpTile(tester, _song());

      await tester.tap(find.text('Hide from library'));
      await tester.pumpAndSettle();

      expect(find.text('Hidden from library'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      verify(() => setHidden(any())).called(1);
      final undo =
          verify(() => setSongsHidden(captureAny())).captured.single
              as SetSongsHiddenParams;
      expect(undo.hidden, isFalse);
      expect(undo.songIds, [7]);
    });

    testWidgets('offers "Remove from playlist" only on a playlist', (
      tester,
    ) async {
      await pumpTile(tester, _song());
      expect(find.text('Remove from playlist'), findsNothing);
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      await pumpTile(tester, _song(), playlist: _playlist);
      expect(find.text('Remove from playlist'), findsOneWidget);
    });
  });
}
