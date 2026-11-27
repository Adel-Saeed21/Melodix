import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/search/search_history.dart';
import 'package:melodix/core/search/search_sources.dart';
import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_results.dart';
import 'package:melodix/features/player/domain/usecases/play_queue_usecase.dart';
import 'package:mocktail/mocktail.dart';

import '../../player/player_fixtures.dart';
import '../../../support/l10n_support.dart';

class _Artwork extends Mock implements GetSongArtworkUseCase {}

/// "Clips", standing in for videos: another feature's results.
class _Clips extends ChangeNotifier implements SearchSource {
  List<String> items = const [];

  @override
  SearchSection? search(BuildContext context, String query) {
    final hits = [
      for (final i in items)
        if (i.toLowerCase().contains(query.toLowerCase())) i,
    ];
    if (hits.isEmpty) return null;
    return SearchSection(
      title: 'Clips',
      count: hits.length,
      itemBuilder: (context, index) => TextButton(
        onPressed: () => context.read<SearchHistoryCubit>().opened(
          OpenedFromSearch(kind: openedKind, id: hits[index]),
          query: query,
        ),
        child: Text('clip: ${hits[index]}'),
      ),
    );
  }

  @override
  String get openedKind => 'clip';

  @override
  Widget? openedTile(BuildContext context, String id) =>
      items.contains(id) ? Text('opened clip: $id') : null;
}

void main() {
  late PlayerHarness player;
  late LibrarySearchCubit search;
  late SearchHistoryCubit history;
  late _Clips clips;
  String? searchedAgain;

  setUpAll(() {
    registerPlayerFallbacks();
    registerFallbackValue(const SongArtworkParams(0));
  });

  setUp(() async {
    await getIt.reset();
    final artwork = _Artwork();
    when(() => artwork(any())).thenReturn(null);
    when(() => artwork.cached(any())).thenReturn(null);
    getIt.registerSingleton<GetSongArtworkUseCase>(artwork);
    player = PlayerHarness(); // also sets up the saved-state storage
    history = SearchHistoryCubit();
    search = LibrarySearchCubit(debounce: Duration.zero)
      ..updateSources(
        songs: [
          playerSong(1, title: 'Sunrise'),
          playerSong(2, title: 'Sunset'),
          playerSong(3, title: 'Moon'),
        ],
      );
    clips = _Clips();
    searchedAgain = null;
  });

  tearDown(() async {
    await search.close();
    await history.close();
    await player.dispose();
    await getIt.reset();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: player.provide(
              MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: search),
                  BlocProvider.value(value: history),
                ],
                child: SearchSources(
                  sources: [clips],
                  child: LibrarySearchResultsView(
                    onQuery: (query) {
                      searchedAgain = query;
                      search.queryChanged(query);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> type(WidgetTester tester, String query) async {
    search.queryChanged(query);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump();
  }

  group('the empty search', () {
    testWidgets('the first time: the usual prompt', (tester) async {
      await pump(tester);
      expect(find.text(english.searchPromptTitle), findsOneWidget);
      expect(find.text(english.recentSearches), findsNothing);
    });

    testWidgets('a song opened from search: it and the search show', (
      tester,
    ) async {
      await pump(tester);
      await type(tester, 'sun');
      await tester.tap(find.text('Sunset'));
      await tester.pump();
      verify(() => player.playQueue(any())).called(1);

      await type(tester, ''); // back to the empty search
      expect(find.text(english.searchPromptTitle), findsNothing);
      expect(find.text(english.recentSearches), findsOneWidget);
      expect(find.text('sun'), findsOneWidget);
      expect(find.text(english.openedFromSearch), findsOneWidget);
      expect(find.text('Sunset'), findsOneWidget);
      expect(find.text('Sunrise'), findsNothing, reason: 'not opened');
    });

    testWidgets('typing alone remembers nothing', (tester) async {
      await pump(tester);
      await type(tester, 's');
      await type(tester, 'su');
      await type(tester, 'sun');
      await type(tester, '');
      expect(find.text(english.searchPromptTitle), findsOneWidget);
    });

    testWidgets('an album, artist or playlist opened: only the search', (
      tester,
    ) async {
      history.searched('moon');
      await pump(tester);
      expect(find.text('moon'), findsOneWidget);
      expect(find.text(english.openedFromSearch), findsNothing);
    });

    testWidgets('a recent search tapped is searched again', (tester) async {
      history.searched('moon');
      await pump(tester);
      await tester.tap(find.text('moon'));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();

      expect(searchedAgain, 'moon');
      expect(find.text('Moon'), findsOneWidget, reason: 'its results');
    });

    testWidgets('✕ forgets one search; Clear forgets everything', (
      tester,
    ) async {
      history
        ..searched('moon')
        ..searched('sun')
        ..opened(const OpenedFromSearch.song(1));
      await pump(tester);

      await tester.tap(find.byTooltip(english.removeRecentSearch).first);
      await tester.pump();
      expect(find.text('sun'), findsNothing);
      expect(find.text('moon'), findsOneWidget);

      await tester.tap(find.text(english.clearSearchHistory));
      await tester.pump();
      expect(find.text(english.searchPromptTitle), findsOneWidget);
    });

    testWidgets("another feature's item (a video) shows with its own row", (
      tester,
    ) async {
      clips.items = ['Beach'];
      await pump(tester);
      await type(tester, 'beach');
      await tester.tap(find.text('clip: Beach'));
      await type(tester, '');

      expect(find.text('opened clip: Beach'), findsOneWidget);
      expect(find.text('beach'), findsOneWidget);
    });

    testWidgets('opened items that are gone are left out', (tester) async {
      history
        ..opened(const OpenedFromSearch.song(404)) // deleted song
        ..opened(const OpenedFromSearch(kind: 'clip', id: 'Gone'))
        ..opened(const OpenedFromSearch(kind: 'unknown', id: '1'));
      await pump(tester);
      // Nothing left to show, and no searches: the usual prompt.
      expect(find.text(english.searchPromptTitle), findsOneWidget);
    });

    testWidgets('an opened song plays the opened songs, from it', (
      tester,
    ) async {
      history
        ..opened(const OpenedFromSearch.song(3))
        ..opened(const OpenedFromSearch.song(1)); // newest first: 1, 3
      await pump(tester);

      await tester.tap(find.text('Moon'));
      await tester.pump();

      final params =
          verify(() => player.playQueue(captureAny())).captured.single
              as PlayQueueParams;
      expect([for (final s in params.songs) s.id], [1, 3]);
      expect(params.startIndex, 1);
      // Opened again: it moves to the top.
      expect(history.state.opened.first, const OpenedFromSearch.song(3));
    });
  });

  group('SearchHistoryCubit', () {
    test('keeps the last 3 searches, newest first, no repeats', () {
      history
        ..searched('a')
        ..searched('b')
        ..searched('  c  ')
        ..searched('B') // the same search, another case
        ..searched('d')
        ..searched('');
      expect(history.state.queries, ['d', 'B', 'c']);
    });

    test('keeps the last 10 opened items, newest first, no repeats', () {
      for (var id = 1; id <= 12; id++) {
        history.opened(OpenedFromSearch.song(id));
      }
      history.opened(const OpenedFromSearch.song(5));
      final ids = [for (final o in history.state.opened) o.id];
      expect(ids, ['5', '12', '11', '10', '9', '8', '7', '6', '4', '3']);
    });

    test('survives a restart, and ignores damaged saved data', () {
      history
        ..searched('moon')
        ..opened(
          const OpenedFromSearch(kind: 'video', id: 'v1'),
          query: 'beach',
        );
      final saved = history.toJson(history.state)!;
      expect(history.fromJson(saved), history.state);

      final damaged = history.fromJson({
        'queries': ['ok', 3, null],
        'opened': [
          {'kind': 'song', 'id': '1'},
          {'kind': 5},
          'junk',
        ],
      })!;
      expect(damaged.queries, ['ok']);
      expect(damaged.opened, [const OpenedFromSearch.song(1)]);
      expect(history.fromJson(const {}), SearchHistory.empty);
    });

    test('is saved through the app\'s saved state', () {
      final storage = HydratedBloc.storage;
      history.searched('moon');
      // A new instance (the next launch) reads it back.
      final next = SearchHistoryCubit();
      expect(next.state.queries, ['moon']);
      expect(HydratedBloc.storage, same(storage));
      next.close();
    });
  });
}
