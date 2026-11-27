import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:melodix/features/lyrics/domain/entities/lyrics.dart';
import 'package:melodix/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:melodix/features/lyrics/presentation/logic/lyrics_clock.dart';
import 'package:melodix/features/lyrics/presentation/logic/lyrics_cubit.dart';
import 'package:melodix/features/lyrics/presentation/widgets/lyrics_view.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

/// A stand-in for whatever plays the song: the position is set by hand,
/// seeks are recorded. (The lyrics view needs nothing else.)
class _FakeClock implements LyricsClock {
  _FakeClock(this.position);

  @override
  Duration position;

  final _changes = StreamController<Duration>.broadcast();
  final seeks = <Duration>[];

  void moveTo(Duration to) => _changes.add(position = to);

  @override
  Stream<Duration> get positions => _changes.stream;

  @override
  Future<void> seek(Duration to) async => seeks.add(to);

  Future<void> close() => _changes.close();
}

/// Synced lyrics on the phone.
class _Repository implements LyricsRepository {
  @override
  Future<Lyrics?> local(Song song) async => const Lyrics(
    lines: [
      LyricLine('First line', time: Duration(seconds: 1)),
      LyricLine('Second line', time: Duration(seconds: 5)),
      LyricLine('Third line', time: Duration(seconds: 9)),
    ],
    source: LyricsSource.file,
  );

  @override
  Future<Either<Failure, Lyrics?>> searchOnline(Song song) =>
      throw UnimplementedError();

  @override
  Future<void> forgetSaved(int songId) => throw UnimplementedError();
}

final _song = Song(
  id: 7,
  title: 'Song',
  artist: 'Band',
  album: 'Album',
  albumId: 1,
  duration: const Duration(minutes: 3),
  path: '/music/song.mp3',
  playbackUri: Uri.parse('content://x/7'),
  isFavorite: false,
  playCount: 0,
);

void main() {
  late _FakeClock clock;
  late LyricsCubit lyrics;

  setUp(() {
    clock = _FakeClock(const Duration(seconds: 6));
    lyrics = LyricsCubit(_Repository());
  });

  tearDown(() async {
    await lyrics.close();
    await clock.close();
  });

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: RepositoryProvider<LyricsClock>.value(
              value: clock,
              child: BlocProvider.value(
                value: lyrics,
                child: const LyricsView(),
              ),
            ),
          ),
        ),
      ),
    );
    await lyrics.show(_song);
    await tester.pumpAndSettle();
  }

  /// The colour [line] is drawn in (its own style, not the page's).
  Color? colorOf(WidgetTester tester, String line) => tester
      .widget<AnimatedDefaultTextStyle>(
        find
            .ancestor(
              of: find.text(line),
              matching: find.byType(AnimatedDefaultTextStyle),
            )
            .first,
      )
      .style
      .color;

  final accent = AppTheme.darkTheme.primaryColor;

  testWidgets('lights the line being sung, and follows the clock', (
    tester,
  ) async {
    await pumpView(tester);
    // 6 s in: the second line.
    expect(colorOf(tester, 'Second line'), accent);
    expect(colorOf(tester, 'Third line'), isNot(accent));

    clock.moveTo(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(colorOf(tester, 'Third line'), accent);
    expect(colorOf(tester, 'Second line'), isNot(accent));
  });

  testWidgets('a tap on a line seeks the clock there', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('First line'));
    expect(clock.seeks, [const Duration(seconds: 1)]);
  });
}
