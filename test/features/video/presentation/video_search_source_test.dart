import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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

  /// A screen's context (search titles its section in the app's language;
  /// English here).
  Future<BuildContext> screen(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    return context;
  }

  testWidgets("doesn't load the library until a search runs", (tester) async {
    final context = await screen(tester);
    verifyNever(() => watch());
    source.search(context, 'a');
    verify(() => watch()).called(1);
    source.search(context, 'b');
    verifyNever(() => watch()); // once
  });

  testWidgets('finds videos by title, any case; tells open results', (
    tester,
  ) async {
    final context = await screen(tester);
    var notified = 0;
    source
      ..addListener(() => notified++)
      ..search(context, 'x'); // starts loading
    library.add([
      titled('1', 'Holiday in Rome'),
      titled('2', 'Birthday'),
      titled('3', 'ROME by night'),
    ]);
    await tester.pump();
    expect(notified, 1);

    final rome = source.search(context, 'rome')!;
    expect(rome.title, 'Videos');
    expect(rome.count, 2);
    expect(source.search(context, 'paris'), isNull);
  });
}
