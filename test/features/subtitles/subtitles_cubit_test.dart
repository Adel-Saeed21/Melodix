import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/subtitles/domain/entities/online_subtitle.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_download.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_failure.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_track.dart';
import 'package:melodix/features/subtitles/domain/usecases/subtitle_usecases.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitle_search_cubit.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitles_cubit.dart';

import 'subtitle_fixtures.dart';

void main() {
  late FakeSubtitleRepository repository;
  late StreamController<String?> videos;
  late SubtitlesCubit cubit;

  const second = Duration(seconds: 2);

  setUp(() {
    repository = FakeSubtitleRepository();
    videos = StreamController<String?>();
    cubit = subtitlesCubitOver(repository, currentVideo: videos.stream);
  });

  tearDown(() async {
    await cubit.close();
    await videos.close();
  });

  group('SubtitlesCubit', () {
    test('a video: its tracks, off until chosen', () async {
      repository.tracks['a'] = [testTrack('t1'), testTrack('t2')];
      await cubit.openVideo('a');

      expect(cubit.state.videoId, 'a');
      expect(cubit.state.tracks, hasLength(2));
      expect(cubit.state.isOn, isFalse);
      expect(cubit.state.status, SubtitlesStatus.ready);
    });

    test('choosing a track shows it, and is remembered', () async {
      repository.tracks['a'] = [testTrack('t1')];
      await cubit.openVideo('a');
      await cubit.select(repository.tracks['a']!.single);

      expect(cubit.state.selectedId, 't1');
      expect(cubit.state.timeline.textAt(second), 't1');
      expect(repository.selected['a'], 't1');

      await cubit.select(null);
      expect(cubit.state.isOn, isFalse);
      expect(cubit.state.timeline.isEmpty, isTrue);
      expect(repository.selected['a'], isNull);
    });

    test('reopening a video brings its choice back', () async {
      repository
        ..tracks['a'] = [testTrack('t1'), testTrack('t2')]
        ..selected['a'] = 't2';
      await cubit.openVideo('a');
      expect(cubit.state.selectedId, 't2');
      expect(cubit.state.timeline.textAt(second), 't2');
    });

    test('follows the video session', () async {
      repository.tracks['b'] = [testTrack('b1', videoId: 'b')];
      videos.add('b');
      await pumpEventQueue();
      expect(cubit.state.videoId, 'b');
      expect(cubit.state.tracks.single.id, 'b1');

      videos.add(null);
      await pumpEventQueue();
      expect(cubit.state.videoId, isNull);
      expect(cubit.state.tracks, isEmpty);
    });

    test('an unreadable track: off, with the reason', () async {
      repository
        ..tracks['a'] = [testTrack('bad')]
        ..unreadable.add('bad');
      await cubit.openVideo('a');
      await cubit.select(repository.tracks['a']!.single);

      expect(cubit.state.isOn, isFalse);
      expect(cubit.state.status, SubtitlesStatus.failed);
      expect(cubit.state.failure, isA<SubtitleFormatFailure>());
    });

    test("an older video's captions never land on the next", () async {
      repository
        ..tracks['a'] = [testTrack('t1')]
        ..selected['a'] = 't1'
        ..loadGate = Completer<void>();
      final opening = cubit.openVideo('a');
      await pumpEventQueue();
      final moving = cubit.openVideo('b');
      repository.loadGate!.complete();
      await opening;
      await moving;

      expect(cubit.state.videoId, 'b');
      expect(cubit.state.timeline.isEmpty, isTrue);
    });

    test('import: the file is added and shown', () async {
      await cubit.openVideo('a');
      repository.toImport = testTrack('new');
      await cubit.importFromDevice();

      expect(cubit.state.tracks.single.id, 'new');
      expect(cubit.state.selectedId, 'new');
      expect(cubit.state.importing, isFalse);
    });

    test('import cancelled: nothing changes', () async {
      await cubit.openVideo('a');
      await cubit.importFromDevice();
      expect(cubit.state.tracks, isEmpty);
      expect(cubit.state.failure, isNull);
    });

    test('tracks failing to load: failed state', () async {
      repository.tracksFailure = const SubtitleStorageFailure();
      await cubit.openVideo('a');
      expect(cubit.state.status, SubtitlesStatus.failed);
    });
  });

  group('SubtitleSearchCubit', () {
    const result = OnlineSubtitle(fileId: 7, title: 'Film', language: 'en');
    late List<SubtitleTrack> used;

    SubtitleSearchCubit search() => SubtitleSearchCubit(
      videoId: 'a',
      search: SearchOnlineSubtitlesUseCase(repository),
      download: DownloadSubtitleUseCase(repository),
      onDownloaded: (track) async => used.add(track),
    );

    setUp(() => used = []);

    test('loading, then the results', () async {
      repository.searchResult = const Right([result]);
      final s = search();
      final states = <SubtitleSearchStatus>[];
      final sub = s.stream.listen((st) => states.add(st.status));
      await s.search('  Film ', language: 'en');
      await pumpEventQueue();

      expect(states, [
        SubtitleSearchStatus.loading,
        SubtitleSearchStatus.success,
      ]);
      expect(s.state.results, [result]);
      expect(repository.searches.single, ('Film', 'en'));
      await sub.cancel();
      await s.close();
    });

    test('an IMDb id searches by it, not by name', () async {
      final s = search();
      await s.search('https://www.imdb.com/title/tt0133093/', language: 'en');
      expect(repository.imdbSearches, [133093]);
      expect(repository.searches.single, (null, 'en'));
      await s.close();
    });

    test('nothing found: empty', () async {
      final s = search();
      await s.search('Film');
      expect(s.state.status, SubtitleSearchStatus.empty);
      await s.close();
    });

    test('a failure keeps its reason', () async {
      repository.searchResult = const Left(
        SubtitleRateLimitFailure(retryAfter: Duration(seconds: 2)),
      );
      final s = search();
      await s.search('Film');
      expect(s.state.status, SubtitleSearchStatus.failure);
      expect(
        s.state.failure,
        const SubtitleRateLimitFailure(retryAfter: Duration(seconds: 2)),
      );
      await s.close();
    });

    test('not set up: says so without searching', () async {
      repository.canSearchOnline = false;
      final s = search();
      await s.search('Film');
      expect(s.state.failure, isA<SubtitleNotConfiguredFailure>());
      expect(repository.searches, isEmpty);
      await s.close();
    });

    test('a download is kept, marked saved and handed on', () async {
      final track = testTrack(
        'downloaded:7',
        source: SubtitleSource.downloaded,
      );
      repository.downloadResult = Right(
        SubtitleDownload(track: track, remaining: 4, resetsIn: '5 hours'),
      );
      final s = search();
      await s.download(result);

      expect(s.state.savedFileIds, {7});
      expect(s.state.remainingDownloads, 4);
      expect(s.state.resetsIn, '5 hours');
      expect(s.state.downloadingFileId, isNull);
      expect(used, [track]);
      await s.close();
    });

    test('a failed download: the reason, nothing handed on', () async {
      repository.downloadResult = const Left(
        SubtitleQuotaFailure(resetsIn: '3 hours'),
      );
      final s = search();
      await s.download(result);

      expect(s.state.downloadFailure, isA<SubtitleQuotaFailure>());
      expect(used, isEmpty);
      await s.close();
    });
  });

  test('IMDb ids: tt-form and links; names are not ids', () {
    expect(parseImdbId('tt0133093'), 133093);
    expect(parseImdbId(' TT0944947 '), 944947);
    expect(parseImdbId('https://m.imdb.com/title/tt0133093'), 133093);
    expect(parseImdbId('The Matrix'), isNull);
    expect(parseImdbId('tt12'), isNull);
    expect(parseImdbId('0133093'), isNull);
  });

  test('the search name comes from the file name', () {
    expect(
      subtitleQueryFor('The.Movie.2020.1080p.mkv'),
      'The Movie 2020 1080p',
    );
    expect(subtitleQueryFor('My_holiday_video.mp4'), 'My holiday video');
    expect(subtitleQueryFor('Dr. Strange'), 'Dr Strange');
  });
}
