import 'package:melodix/core/service/system_delete_confirmation.dart';

import '../../player/player_fixtures.dart';

import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:dartz/dartz.dart';
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
import 'package:melodix/features/music_library/domain/usecases/get_playlists_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/remove_song_from_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/set_songs_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/delete_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_song_favorite_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_actions_scope.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_options_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_tile.dart';
import 'package:mocktail/mocktail.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_song_favorite_usecase.dart';
import '../../../support/l10n_support.dart';

class MockToggleFavorite extends Mock implements ToggleSongFavoriteUseCase {}

class MockWatchFavorite extends Mock implements WatchSongFavoriteUseCase {}

class MockGetPlaylists extends Mock implements GetPlaylistsUseCase {}

class MockCreatePlaylist extends Mock implements CreatePlaylistUseCase {}

class MockAddToPlaylist extends Mock implements AddSongsToPlaylistUseCase {}

class MockGetArtwork extends Mock implements GetSongArtworkUseCase {}

class MockRemoveFromPlaylist extends Mock
    implements RemoveSongFromPlaylistUseCase {}

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
  late MockGetPlaylists getPlaylists;
  late MockCreatePlaylist createPlaylist;
  late MockAddToPlaylist addToPlaylist;
  late MockRemoveFromPlaylist removeFromPlaylist;
  late MockSetSongsFavorite setSongsFavorite;
  late MockDeleteSongs deleteSongs;

  setUpAll(() {
    registerPlayerFallbacks();
    registerFallbackValue(const AddSongsToPlaylistParams(0, []));
    registerFallbackValue(const CreatePlaylistParams(''));
    registerFallbackValue(const NoParams());
    registerFallbackValue(const SongArtworkParams(0));
    registerFallbackValue(_song());
    registerFallbackValue(const RemoveSongFromPlaylistParams(0, 0));
    registerFallbackValue(const SetSongsFavoriteParams([], favorite: true));
    registerFallbackValue(<int>[]);
  });

  setUp(() {
    toggleFavorite = MockToggleFavorite();
    getPlaylists = MockGetPlaylists();
    createPlaylist = MockCreatePlaylist();
    addToPlaylist = MockAddToPlaylist();
    removeFromPlaylist = MockRemoveFromPlaylist();
    setSongsFavorite = MockSetSongsFavorite();
    deleteSongs = MockDeleteSongs();
    when(() => deleteSongs.isSupported).thenReturn(true);
  });

  SongActionsCubit buildCubit() => SongActionsCubit(
    toggleFavorite: toggleFavorite,
    watchFavorite: MockWatchFavorite(),
    getPlaylists: getPlaylists,
    createPlaylist: createPlaylist,
    addToPlaylist: addToPlaylist,
    removeFromPlaylist: removeFromPlaylist,
    setSongsFavorite: setSongsFavorite,
    deleteSongs: deleteSongs,
  );

  group('SongActionsCubit', () {
    test('toggleFavorite reports the new state', () async {
      when(() => toggleFavorite(7)).thenAnswer((_) async => const Right(true));
      final cubit = buildCubit();

      await cubit.toggleFavorite(_song());

      expect(cubit.state?.message(english), 'Added to favourites');
      await cubit.close();
    });

    test('addToPlaylist reports added vs already there', () async {
      when(() => addToPlaylist(any())).thenAnswer((_) async => const Right(1));
      final cubit = buildCubit();
      await cubit.addToPlaylist(_song(), _playlist);
      expect(cubit.state?.message(english), 'Added to "Road trip"');

      when(() => addToPlaylist(any())).thenAnswer((_) async => const Right(0));
      await cubit.addToPlaylist(_song(), _playlist);
      expect(cubit.state?.message(english), 'Already in "Road trip"');
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
      expect(cubit.state?.message(english), 'Added to "Chill"');
      await cubit.close();
    });

    test('failures surface their message', () async {
      when(() => toggleFavorite(7))
          .thenAnswer((_) async => const Left(LibraryFailure('Nope')));
      final cubit = buildCubit();

      await cubit.toggleFavorite(_song());

      expect(cubit.state?.message(english), 'Nope');
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
      expect(cubit.state?.message(english), 'Removed from "Road trip"');
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
        expect(cubit.state?.message(english), 'Added 2 songs to favourites');

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

      test('addManyToPlaylist reports the count', () async {
        when(() => addToPlaylist(any()))
            .thenAnswer((_) async => const Right(2));
        final cubit = buildCubit();

        expect(await cubit.addManyToPlaylist(songs, _playlist), isTrue);

        expect(cubit.state?.message(english), 'Added 2 songs to "Road trip"');
        await cubit.close();
      });

      test(
        'deleteMany reports deleted songs, or nothing when declined',
        () async {
          final cubit = buildCubit();
          when(() => deleteSongs(any()))
              .thenAnswer((_) async => const Right(2));
          expect(await cubit.deleteMany(songs), isTrue);
          expect(cubit.state?.message(english), 'Deleted 2 songs');

          when(() => deleteSongs(any()))
              .thenAnswer((_) async => const Right(0));
          expect(await cubit.deleteMany(songs), isFalse);
          expect(cubit.state?.message(english), 'No songs were deleted');
          expect(cubit.canDeleteSongs, isTrue);
          await cubit.close();
        },
      );
    });

    test('albumFor / artistFor find them in the library', () async {
      final cubit = buildCubit();
      final song = _song();

      expect(cubit.albumFor(song, [song])?.songCount, 1);
      expect(cubit.artistFor(song, [song])?.name, song.artist);
      expect(cubit.state, isNull); // nothing to report
      await cubit.close();
    });

    test('albumFor / artistFor report when they are gone', () async {
      final cubit = buildCubit();

      expect(cubit.albumFor(_song(), const []), isNull);
      expect(
        cubit.state?.message(english),
        'This album is no longer in your library',
      );
      expect(cubit.artistFor(_song(), const []), isNull);
      expect(
        cubit.state?.message(english),
        'This artist is no longer in your library',
      );
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

    late PlayerHarness player;

    Future<void> pumpTile(
      WidgetTester tester,
      Song song, {
      Playlist? playlist,
    }) async {
      // The player the menu's queue items act on (made inside the test:
      // its streams run on the test's clock).
      player = PlayerHarness();
      addTearDown(player.dispose);
      await tester.pumpWidget(
        AppScreenUtilInit(
          child: player.provide(
            MaterialApp(
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
        ),
      );
      await tester.tap(find.byTooltip('Song options'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows every option; play next and queue are on', (
      tester,
    ) async {
      await pumpTile(tester, _song());

      for (final label in [
        'Play next',
        'Add to queue',
        'Add to favourites',
        'Add to playlist',
        'Go to album',
        'Go to artist',
        'Delete from phone',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Hide from library'), findsNothing);
      final playNext = tester.widget<PopupMenuItem<Object?>>(
        find.ancestor(
          of: find.text('Play next'),
          matching: find.byWidgetPredicate((w) => w is PopupMenuItem),
        ),
      );
      expect(playNext.enabled, isTrue);
    });

    testWidgets('play next: right after the current song, and says so', (
      tester,
    ) async {
      final song = _song();
      await pumpTile(tester, song);
      await tester.tap(find.text('Play next'));
      await tester.pumpAndSettle();

      verify(() => player.editQueue.playNext([song])).called(1);
      expect(find.text('Plays next'), findsOneWidget);
    });

    testWidgets('add to queue: at the end, and says so', (tester) async {
      final song = _song();
      await pumpTile(tester, song);
      await tester.tap(find.text('Add to queue'));
      await tester.pumpAndSettle();

      verify(() => player.editQueue.addToQueue([song])).called(1);
      expect(find.text('Added to queue'), findsOneWidget);
    });

    testWidgets('delete from phone: asks first, then deletes', (tester) async {
      when(() => deleteSongs(any())).thenAnswer((_) async => const Right(1));
      await pumpTile(tester, _song());
      await tester.tap(find.text('Delete from phone'));
      await tester.pumpAndSettle();

      expect(find.text('Delete 1 song?'), findsOneWidget);
      verifyNever(() => deleteSongs(any()));
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();
      verify(() => deleteSongs([7])).called(1);
    });

    testWidgets('delete from phone on Android 11+: only the system asks', (
      tester,
    ) async {
      SystemDeleteConfirmation.debugOverride(true);
      addTearDown(() => SystemDeleteConfirmation.debugOverride(null));
      when(() => deleteSongs(any())).thenAnswer((_) async => const Right(1));
      await pumpTile(tester, _song());
      await tester.tap(find.text('Delete from phone'));
      await tester.pumpAndSettle();

      expect(find.text('Delete 1 song?'), findsNothing, reason: 'no 2nd ask');
      verify(() => deleteSongs([7])).called(1);
    });

    testWidgets("delete isn't offered where it isn't supported", (
      tester,
    ) async {
      when(() => deleteSongs.isSupported).thenReturn(false);
      await pumpTile(tester, _song());
      expect(find.text('Delete from phone'), findsNothing);
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
