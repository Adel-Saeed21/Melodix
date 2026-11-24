import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/music_library/domain/repositories/artwork_repository.dart';
import 'package:melodix/features/player/data/background/now_playing_artwork_files.dart';
import 'package:mocktail/mocktail.dart';

import '../player_fixtures.dart';

class MockArtwork extends Mock implements ArtworkRepository {}

void main() {
  late Directory dir;
  late MockArtwork artwork;
  var fallbackRenders = 0;

  NowPlayingArtworkFiles files({int keep = 30}) => NowPlayingArtworkFiles(
    artwork: artwork,
    directory: () async => Directory('${dir.path}/covers'),
    fallbackCover: () async {
      fallbackRenders++;
      return Uint8List.fromList([0xFA, 0x11]);
    },
    keep: keep,
  );

  /// Songs with these ids have no cover of their own.
  void withoutCover(List<int> ids) => when(
    () => artwork.getArtwork(
      any(that: isIn(ids)),
      size: any(named: 'size'),
    ),
  ).thenAnswer((_) async => null);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('covers_test');
    artwork = MockArtwork();
    fallbackRenders = 0;
    when(
      () => artwork.getArtwork(any(), size: any(named: 'size')),
    ).thenAnswer((i) async => Uint8List.fromList([i.positionalArguments[0]]));
  });

  tearDown(() => dir.delete(recursive: true));

  test('writes the cover once and reuses the file', () async {
    final covers = files();

    final uri = await covers.uriFor(playerSong(7));
    final again = await covers.uriFor(playerSong(7));

    expect(uri, isNotNull);
    expect(again, uri);
    expect(await File.fromUri(uri!).readAsBytes(), [7]);
    verify(() => artwork.getArtwork(7, size: 512)).called(1);
  });

  test('songs with a cover keep their own', () async {
    final uri = await files().uriFor(playerSong(7));

    expect(uri!.pathSegments.last, '7.jpg');
    expect(fallbackRenders, 0);
  });

  test('songs without a cover share the branded fallback', () async {
    withoutCover([3, 4]);
    final covers = files();

    final first = await covers.uriFor(playerSong(3));
    final second = await covers.uriFor(playerSong(4));

    expect(first, isNotNull);
    expect(second, first);
    expect(await File.fromUri(first!).readAsBytes(), [0xFA, 0x11]);
    expect(fallbackRenders, 1); // drawn once
    expect(File('${dir.path}/covers/3.jpg').existsSync(), isFalse);
  });

  test('keeps only the most recent covers', () async {
    final covers = files(keep: 3);
    for (var id = 1; id <= 5; id++) {
      await covers.uriFor(playerSong(id));
      // Distinct modification times on coarse file systems.
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    final left = Directory('${dir.path}/covers')
        .listSync()
        .map((f) => f.uri.pathSegments.last)
        .toSet();
    expect(left, {'3.jpg', '4.jpg', '5.jpg'});
  });

  test('the fallback survives pruning', () async {
    withoutCover([99]);
    final covers = files(keep: 2);
    final fallback = await covers.uriFor(playerSong(99));
    for (var id = 1; id <= 4; id++) {
      await covers.uriFor(playerSong(id));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    expect(File.fromUri(fallback!).existsSync(), isTrue);
  });
}
