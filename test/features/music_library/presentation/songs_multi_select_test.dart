import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_sort_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_tabs.dart';
import 'package:mocktail/mocktail.dart';

class MockGetArtwork extends Mock implements GetSongArtworkUseCase {}

class MockActions extends Mock implements SongActionsCubit {}

class MockStorage extends Mock implements Storage {}

Song _song(int id) => Song(
  id: id,
  title: 'Track $id',
  artist: 'Artist',
  album: 'Album',
  albumId: 1,
  duration: const Duration(minutes: 3),
  path: '/m/$id.mp3',
  playbackUri: Uri.parse('content://media/external/audio/media/$id'),
  isFavorite: false,
  playCount: 0,
);

void main() {
  late MockActions actions;

  setUpAll(() => registerFallbackValue(const SongArtworkParams(0)));

  setUp(() async {
    await getIt.reset();
    final artwork = MockGetArtwork();
    when(() => artwork(any())).thenAnswer((_) async => null);
    getIt.registerSingleton<GetSongArtworkUseCase>(artwork);

    final storage = MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;

    actions = MockActions();
    when(() => actions.state).thenReturn(null);
    when(() => actions.stream).thenAnswer((_) => const Stream.empty());
    when(() => actions.close()).thenAnswer((_) async {});
    when(() => actions.canDeleteSongs).thenReturn(true);
  });

  tearDown(() => getIt.reset());

  Future<void> pumpTab(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(375, 812),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<SongActionsCubit>.value(value: actions),
                BlocProvider(create: (_) => SongSortCubit()),
              ],
              child: SongsTab(
                songs: [_song(1), _song(2), _song(3)],
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the select icon enters selection mode with an action bar', (
    tester,
  ) async {
    await pumpTab(tester);
    expect(find.byTooltip('Song options'), findsNWidgets(3));

    await tester.tap(find.byTooltip('Select songs'));
    await tester.pumpAndSettle();

    expect(find.text('0 selected'), findsOneWidget);
    expect(find.text('Select all'), findsOneWidget);
    expect(find.byTooltip('Song options'), findsNothing); // ⋮ hidden
    for (final label in ['Playlist', 'Favourite', 'Hide', 'Delete']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('long-press selects, tap toggles, select all, then exit', (
    tester,
  ) async {
    await pumpTab(tester);

    await tester.longPress(find.text('Track 2'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.text('Track 3'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(find.text('3 selected'), findsOneWidget);
    expect(find.text('Deselect all'), findsOneWidget);

    await tester.tap(find.byTooltip('Cancel selection'));
    await tester.pumpAndSettle();
    expect(find.text('3 selected'), findsNothing);
    expect(find.byTooltip('Select songs'), findsOneWidget);
  });

  testWidgets('hide acts on the selection and leaves selection mode', (
    tester,
  ) async {
    when(() => actions.hideMany(any())).thenAnswer((_) async => true);
    await pumpTab(tester);

    await tester.longPress(find.text('Track 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Track 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();

    final hidden =
        verify(() => actions.hideMany(captureAny())).captured.single
            as List<Song>;
    expect(hidden.map((s) => s.id).toSet(), {1, 3});
    expect(find.byTooltip('Select songs'), findsOneWidget);
  });

  testWidgets('delete asks first and does nothing when cancelled', (
    tester,
  ) async {
    await pumpTab(tester);

    await tester.longPress(find.text('Track 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete 1 song?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => actions.deleteMany(any()));
    expect(find.text('1 selected'), findsOneWidget); // still selecting
  });

  testWidgets('delete is not offered where the platform cannot delete', (
    tester,
  ) async {
    when(() => actions.canDeleteSongs).thenReturn(false);
    await pumpTab(tester);

    await tester.tap(find.byTooltip('Select songs'));
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsNothing);
    expect(find.text('Hide'), findsOneWidget);
  });

  testWidgets('the select icon stays in place whatever the sort label', (
    tester,
  ) async {
    await pumpTab(tester);
    Offset iconAt() => tester.getCenter(find.byTooltip('Select songs'));

    final withRecentlyAdded = iconAt(); // longest label
    for (final label in ['A–Z', 'Most played', 'Recently added']) {
      await tester.tap(find.byTooltip('Sort by'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(iconAt(), withRecentlyAdded, reason: label);
    }
  });
}
