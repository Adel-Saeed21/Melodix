import 'package:melodix/core/widgets/app_screen_util_init.dart';

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';
import 'package:mocktail/mocktail.dart';

class MockGetArtwork extends Mock implements GetSongArtworkUseCase {}

/// A 1×1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  late MockGetArtwork artwork;

  setUpAll(() => registerFallbackValue(const SongArtworkParams(0)));

  setUp(() async {
    await getIt.reset();
    artwork = MockGetArtwork();
    getIt.registerSingleton<GetSongArtworkUseCase>(artwork);
  });

  tearDown(() => getIt.reset());

  Future<void> pump(WidgetTester tester, int songId) => tester.pumpWidget(
    AppScreenUtilInit(
      child: MaterialApp(
        home: Center(child: SongArtwork(songId: songId, size: 48)),
      ),
    ),
  );

  final cover = find.byType(Image);
  final placeholder = find.byIcon(Icons.music_note_rounded);

  testWidgets('a cached cover shows in the first frame (no flash)', (
    tester,
  ) async {
    // Synchronous answer = cached.
    when(() => artwork(any())).thenReturn(_png);

    await pump(tester, 1);

    expect(cover, findsOneWidget);
    expect(placeholder, findsNothing);
  });

  testWidgets('an uncached cover shows the placeholder, then the cover', (
    tester,
  ) async {
    final pending = Completer<Uint8List?>();
    when(() => artwork(any())).thenAnswer((_) => pending.future);

    await pump(tester, 1);
    expect(placeholder, findsOneWidget);

    pending.complete(_png);
    await tester.pump();
    expect(cover, findsOneWidget);
  });

  testWidgets('switching songs never shows the previous song\'s cover', (
    tester,
  ) async {
    final second = Completer<Uint8List?>();
    when(() => artwork(any(that: _forSong(1)))).thenReturn(_png);
    when(() => artwork(any(that: _forSong(2))))
        .thenAnswer((_) => second.future);

    await pump(tester, 1);
    expect(cover, findsOneWidget);

    await pump(tester, 2);
    expect(placeholder, findsOneWidget);
    expect(cover, findsNothing);
  });
}

Matcher _forSong(int id) =>
    isA<SongArtworkParams>().having((p) => p.songId, 'songId', id);
