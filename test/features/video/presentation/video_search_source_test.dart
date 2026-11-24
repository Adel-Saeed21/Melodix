import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/usecases/watch_videos_usecase.dart';
import 'package:melodix/features/video/presentation/search/video_search_source.dart';
import 'package:mocktail/mocktail.dart';

import '../video_fixtures.dart';

class MockWatchVideos extends Mock implements WatchVideosUseCase {}

Video titled(String id, String title) {
  final v = testVideo(id);
  return Video(
    id: v.id,
    title: title,
    duration: v.duration,
    width: v.width,
    height: v.height,
    createdAt: v.createdAt,
    isFavorite: false,
  );
}

void main() {
  late StreamController<List<Video>> library;
  late MockWatchVideos watch;
  late VideoSearchSource source;

  setUp(() {
    library = StreamController<List<Video>>.broadcast();
    watch = MockWatchVideos();
    when(() => watch()).thenAnswer((_) => library.stream);
    source = VideoSearchSource(watch);
  });

  tearDown(() async {
    source.dispose();
    await library.close();
  });

  test("doesn't load the library until a search runs", () {
    verifyNever(() => watch());
    source.search('a');
    verify(() => watch()).called(1);
    source.search('b');
    verifyNever(() => watch()); // once
  });

  test('finds videos by title, any case; tells open results', () async {
    var notified = 0;
    source
      ..addListener(() => notified++)
      ..search('x'); // starts loading
    library.add([
      titled('1', 'Holiday in Rome'),
      titled('2', 'Birthday'),
      titled('3', 'ROME by night'),
    ]);
    await pumpEventQueue();
    expect(notified, 1);

    final rome = source.search('rome')!;
    expect(rome.title, 'Videos');
    expect(rome.count, 2);
    expect(source.search('paris'), isNull);
  });
}
