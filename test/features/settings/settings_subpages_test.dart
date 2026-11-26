import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/preferences/library_filter.dart';
import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:melodix/features/player/domain/entities/equalizer_preset.dart';
import 'package:melodix/features/player/presentation/logic/audio_settings_cubit.dart';
import 'package:melodix/features/player/presentation/pages/equalizer_page.dart';
import 'package:melodix/features/settings/presentation/pages/library_filters_page.dart';
import 'package:melodix/features/stats/presentation/pages/listening_stats_page.dart';
import 'package:mocktail/mocktail.dart';

import '../player/player_fixtures.dart';

class _Library extends Mock implements MusicLibraryBloc {}

class _Artwork extends Mock implements GetSongArtworkUseCase {}

Song _song(int id, String path, {int plays = 0, String artist = 'Ana'}) => Song(
  id: id,
  title: 'Song $id',
  artist: artist,
  album: 'Album',
  albumId: 1,
  duration: const Duration(minutes: 3),
  path: path,
  playbackUri: Uri.parse('content://x/$id'),
  isFavorite: false,
  playCount: plays,
);

void main() {
  late _Library library;
  late AudioSettingsCubit audio;
  late LibraryFilterCubit filters;

  setUpAll(() => registerFallbackValue(const SongArtworkParams(0)));

  setUp(() async {
    HydratedBloc.storage = MemoryStorage();
    audio = AudioSettingsCubit();
    filters = LibraryFilterCubit();
    library = _Library();
    when(() => library.state).thenReturn(
      MusicLibraryState(
        songs: [
          _song(1, '/music/Rock/a.mp3', plays: 12),
          _song(2, '/music/Rock/b.mp3', plays: 3, artist: 'Ben'),
          _song(3, '/music/Voice notes/c.mp3'),
        ],
      ),
    );
    when(() => library.stream).thenAnswer((_) => const Stream.empty());
    await getIt.reset();
    final artwork = _Artwork();
    when(() => artwork(any())).thenAnswer((_) async => null);
    getIt.registerSingleton<GetSongArtworkUseCase>(artwork);
  });

  tearDown(() async {
    await audio.close();
    await filters.close();
    await getIt.reset();
  });

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<MusicLibraryBloc>.value(value: library),
          BlocProvider.value(value: audio),
          BlocProvider.value(value: filters),
        ],
        child: AppScreenUtilInit(
          child: MaterialApp(theme: AppTheme.darkTheme, home: page),
        ),
      ),
    );
    await tester.pump();
  }

  group('equalizer', () {
    testWidgets('a preset turns it on; moving a bar makes it Custom', (
      tester,
    ) async {
      await pump(tester, const EqualizerPage(supported: true));
      expect(audio.state.equalizerOn, isFalse);
      await tester.tap(find.text('Rock'));
      await tester.pump();
      expect(audio.state.preset, EqualizerPreset.rock);
      expect(audio.state.equalizerOn, isTrue);

      await tester.drag(find.byType(Slider).first, const Offset(0, -60));
      await tester.pump();
      expect(audio.state.preset, EqualizerPreset.custom);
      expect(find.text('Custom'), findsWidgets);
    });

    testWidgets('a phone without one: only a note', (tester) async {
      await pump(tester, const EqualizerPage(supported: false));
      expect(
        find.text("This phone doesn't offer an equalizer to apps."),
        findsOneWidget,
      );
      expect(find.byType(Slider), findsNothing);
    });
  });

  testWidgets('your Melodix: time, top song and top artist', (tester) async {
    await pump(tester, const ListeningStatsPage());
    expect(find.text('45 min'), findsOneWidget); // 15 plays × 3 min
    expect(find.text('Your top artist: Ana'), findsOneWidget);
    expect(find.text('12 plays'), findsWidgets);
  });

  testWidgets('music filters: a folder off, the shortest song', (tester) async {
    await pump(tester, const LibraryFiltersPage());
    expect(find.text('Rock'), findsOneWidget);
    expect(find.text('2 songs · /music/Rock'), findsOneWidget);

    await tester.tap(find.text('Voice notes'));
    await tester.pump();
    expect(filters.state.excludedFolders, {'/music/Voice notes'});

    await tester.tap(find.text('2 min'));
    await tester.pump();
    expect(filters.state.minSeconds, 120);
  });
}
