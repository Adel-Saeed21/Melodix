import 'package:dartz/dartz.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_list_body.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockGetArtwork extends Mock implements GetSongArtworkUseCase {}

class MockSongActionsCubit extends Mock implements SongActionsCubit {}

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

final _songs = [_song(1), _song(2), _song(3)];

void main() {
  setUpAll(() => registerFallbackValue(const SongArtworkParams(0)));

  group('SongListCubit.reorder', () {
    test('shows the new order immediately and saves it', () async {
      List<int>? saved;
      final cubit = SongListCubit(
        () async => Right(_songs),
        saveOrder: (songs) async {
          saved = [for (final s in songs) s.id];
          return const Right(unit);
        },
      );
      await cubit.load();

      await cubit.reorder(0, 2);

      expect(cubit.state.songs.map((s) => s.id), [2, 3, 1]);
      expect(saved, [2, 3, 1]);
      expect(cubit.state.reorderFailures, 0);
      await cubit.close();
    });

    test('reverts and counts the failure when saving fails', () async {
      final cubit = SongListCubit(
        () async => Right(_songs),
        saveOrder: (_) async => const Left(LibraryFailure('db')),
      );
      await cubit.load();

      await cubit.reorder(2, 0);

      expect(cubit.state.songs.map((s) => s.id), [1, 2, 3]);
      expect(cubit.state.reorderFailures, 1);
      await cubit.close();
    });

    test('ignores no-op moves and lists that cannot be reordered', () async {
      var saves = 0;
      final reorderable = SongListCubit(
        () async => Right(_songs),
        saveOrder: (_) async {
          saves++;
          return const Right(unit);
        },
      );
      await reorderable.load();
      await reorderable.reorder(1, 1);
      expect(saves, 0);

      final fixed = SongListCubit(() async => Right(_songs));
      await fixed.load();
      await fixed.reorder(0, 2);
      expect(fixed.canReorder, isFalse);
      expect(fixed.state.songs.map((s) => s.id), [1, 2, 3]);

      await reorderable.close();
      await fixed.close();
    });
  });

  group('reorderable playlist list', () {
    setUp(() async {
      await getIt.reset();
      final artwork = MockGetArtwork();
      when(() => artwork(any())).thenAnswer((_) async => null);
      getIt
        ..registerSingleton<GetSongArtworkUseCase>(artwork)
        ..registerFactory<SongActionsCubit>(() {
          final actions = MockSongActionsCubit();
          when(() => actions.state).thenReturn(null);
          when(() => actions.stream).thenAnswer((_) => const Stream.empty());
          when(() => actions.close()).thenAnswer((_) async {});
          return actions;
        });
    });

    tearDown(() => getIt.reset());

    Future<SongListCubit> pumpList(
      WidgetTester tester, {
      required Future<Either<Failure, Unit>> Function(List<Song>) save,
    }) async {
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final cubit = SongListCubit(() async => Right(_songs), saveOrder: save);
      await cubit.load();
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: BlocProvider.value(
                value: cubit,
                child: const SongListBody(header: SizedBox(height: 40)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return cubit;
    }

    List<String> visibleTitles(WidgetTester tester) {
      final titles = tester
          .widgetList<Text>(find.textContaining('Track '))
          .map((t) => t.data!)
          .toList();
      titles.sort(
        (a, b) => tester
            .getTopLeft(find.text(a))
            .dy
            .compareTo(tester.getTopLeft(find.text(b)).dy),
      );
      return titles;
    }

    testWidgets('each row has a drag handle', (tester) async {
      await pumpList(tester, save: (_) async => const Right(unit));

      expect(find.byTooltip('Drag to reorder'), findsNWidgets(3));
      expect(visibleTitles(tester), ['Track 1', 'Track 2', 'Track 3']);
    });

    testWidgets('dragging the handle moves the song and saves the order', (
      tester,
    ) async {
      List<int>? saved;
      await pumpList(
        tester,
        save: (songs) async {
          saved = [for (final s in songs) s.id];
          return const Right(unit);
        },
      );

      final handle = find.byTooltip('Drag to reorder').first;
      final rowHeight = tester
          .getSize(find.byType(ReorderableDelayedDragStartListener).first)
          .height;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(0, rowHeight * 2.2 / 10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(visibleTitles(tester), ['Track 2', 'Track 3', 'Track 1']);
      expect(saved, [2, 3, 1]);
    });

    testWidgets('a failed save shows a message', (tester) async {
      final cubit = await pumpList(
        tester,
        save: (_) async => const Left(LibraryFailure('db')),
      );

      await cubit.reorder(0, 2);
      await tester.pumpAndSettle();

      expect(find.text("Couldn't save the new order"), findsOneWidget);
      expect(visibleTitles(tester), ['Track 1', 'Track 2', 'Track 3']);
    });
  });
}
