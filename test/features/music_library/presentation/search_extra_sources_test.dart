import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:melodix/core/search/search_history.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/search/search_sources.dart';
import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_results.dart';

import '../../player/player_fixtures.dart';

/// A source of "clips", standing in for videos.
class FakeSource extends ChangeNotifier implements SearchSource {
  List<String> items = const [];

  void update(List<String> next) {
    items = next;
    notifyListeners();
  }

  @override
  SearchSection? search(String query) {
    final hits = [
      for (final i in items)
        if (i.toLowerCase().contains(query.toLowerCase())) i,
    ];
    if (hits.isEmpty) return null;
    return SearchSection(
      title: 'Clips',
      count: hits.length,
      itemBuilder: (_, index) => Text('clip: ${hits[index]}'),
    );
  }

  @override
  String get openedKind => 'clip';

  @override
  Widget? openedTile(BuildContext context, String id) =>
      items.contains(id) ? Text('opened clip: $id') : null;
}

class MockArtwork extends Mock implements GetSongArtworkUseCase {}

void main() {
  late LibrarySearchCubit search;
  late FakeSource source;

  setUpAll(() => registerFallbackValue(const SongArtworkParams(0)));

  setUp(() async {
    await getIt.reset();
    final artwork = MockArtwork();
    when(() => artwork(any())).thenReturn(null);
    when(() => artwork.cached(any())).thenReturn(null);
    getIt.registerSingleton<GetSongArtworkUseCase>(artwork);
    HydratedBloc.storage = MemoryStorage();
    search = LibrarySearchCubit(debounce: Duration.zero)
      ..updateSources(songs: [playerSong(1, title: 'Sunrise')]);
    source = FakeSource();
  });

  tearDown(() async {
    await search.close();
    await getIt.reset();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: search),
                BlocProvider(create: (_) => SearchHistoryCubit()),
              ],
              child: SearchSources(
                sources: [source],
                child: const LibrarySearchResultsView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> type(WidgetTester tester, String query) async {
    search.queryChanged(query);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump();
  }

  testWidgets("a plugged-in source's results show as their own group", (
    tester,
  ) async {
    source.items = ['Sunrise timelapse', 'Beach'];
    await pump(tester);
    await type(tester, 'sun');

    expect(find.text('Songs'), findsOneWidget);
    expect(find.text('Sunrise'), findsOneWidget);
    expect(find.text('Clips'), findsOneWidget);
    expect(find.text('clip: Sunrise timelapse'), findsOneWidget);
    expect(find.text('clip: Beach'), findsNothing);
  });

  testWidgets('only the source matches: results, not "no results"', (
    tester,
  ) async {
    source.items = ['Beach'];
    await pump(tester);
    await type(tester, 'beach');

    expect(find.text('Songs'), findsNothing);
    expect(find.text('clip: Beach'), findsOneWidget);
    expect(find.textContaining('No results'), findsNothing);
  });

  testWidgets('new data in the source updates open results', (tester) async {
    await pump(tester);
    await type(tester, 'beach');
    expect(find.text('clip: Beach'), findsNothing);

    source.update(['Beach']);
    await tester.pump();
    expect(find.text('clip: Beach'), findsOneWidget);
  });

  testWidgets('a long group shows a few, then "Show all"', (tester) async {
    source.items = [for (var i = 1; i <= 7; i++) 'Beach $i'];
    await pump(tester);
    await type(tester, 'beach');

    expect(find.textContaining('clip: '), findsNWidgets(3));
    await tester.tap(find.textContaining('Show all'));
    await tester.pump();
    expect(find.textContaining('clip: '), findsNWidgets(7));
  });
}
