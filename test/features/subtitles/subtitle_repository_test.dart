import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_models.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_remote_data_source.dart';
import 'package:melodix/features/subtitles/data/datasources/subtitle_device_source.dart';
import 'package:melodix/features/subtitles/data/datasources/subtitle_local_storage.dart';
import 'package:melodix/features/subtitles/data/repositories/subtitle_repository_impl.dart';
import 'package:melodix/features/subtitles/domain/entities/online_subtitle.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_failure.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_track.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements OpenSubtitlesRemoteDataSource {}

class FakeDevice implements SubtitleDeviceSource {
  String? path;
  List<File> nearby = const [];
  DeviceSubtitleFile? picked;
  Object? pickError;

  @override
  bool get canPick => true;

  @override
  Future<String?> videoPath(Uri playbackUri) async => path;

  @override
  Future<List<File>> nearbySubtitles(String videoPath) async => nearby;

  @override
  Future<DeviceSubtitleFile?> pick() async {
    if (pickError case final error?) throw error;
    return picked;
  }
}

const srt = '1\n00:00:01,000 --> 00:00:02,000\nHello\n';
Uint8List bytesOf(String text) => Uint8List.fromList(utf8.encode(text));

void main() {
  late Directory dir;
  late SubtitleLocalStorage storage;
  late FakeDevice device;
  late MockRemote remote;
  late SubtitleRepositoryImpl repository;
  final hashed = <String>[];

  const online = OnlineSubtitle(
    fileId: 42,
    title: 'Film.2020.1080p',
    language: 'en',
    fileName: 'Film.srt',
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('subtitles_test');
    storage = SubtitleLocalStorage(
      root: () async => Directory('${dir.path}/subtitles'),
    );
    device = FakeDevice();
    remote = MockRemote();
    when(() => remote.isConfigured).thenReturn(true);
    hashed.clear();
    repository = SubtitleRepositoryImpl(
      storage: storage,
      device: device,
      remote: remote,
      playbackUri: (id) async => Uri.parse('content://media/$id'),
      hash: (file) async {
        hashed.add(file.path);
        return 'abcdef0123456789';
      },
    );
  });

  tearDown(() => dir.delete(recursive: true));

  group('local storage', () {
    test('keeps tracks and the choice per video, across instances', () async {
      final track = await storage.save(
        videoId: 'a/1',
        id: 'imported:x.srt',
        label: 'x.srt',
        source: SubtitleSource.imported,
        extension: 'srt',
        bytes: bytesOf(srt),
        language: 'en',
      );
      await storage.setSelected('a/1', track.id);

      final again = SubtitleLocalStorage(
        root: () async => Directory('${dir.path}/subtitles'),
      );
      expect(await again.tracks('a/1'), [track]);
      expect(await again.selected('a/1'), track.id);
      expect(await again.tracks('b'), isEmpty);
      expect(await File(track.path).readAsString(), srt);
    });

    test('a track whose file is gone is left out', () async {
      final track = await storage.save(
        videoId: 'a',
        id: 't',
        label: 't',
        source: SubtitleSource.imported,
        extension: 'srt',
        bytes: bytesOf(srt),
      );
      await File(track.path).delete();
      expect(await storage.tracks('a'), isEmpty);
    });

    test('a damaged index reads as empty, not an error', () async {
      final index = File('${dir.path}/subtitles/a/index.json');
      await index.create(recursive: true);
      await index.writeAsString('{not json');
      expect(await storage.tracks('a'), isEmpty);
      expect(await storage.selected('a'), isNull);
    });
  });

  group('tracks', () {
    test('saved ones, then files next to the video', () async {
      final saved = await storage.save(
        videoId: 'a',
        id: 'imported:x.srt',
        label: 'x.srt',
        source: SubtitleSource.imported,
        extension: 'srt',
        bytes: bytesOf(srt),
      );
      device
        ..path = '/movies/Film.mkv'
        ..nearby = [File('/movies/Film.en.srt')];

      final tracks = (await repository.tracksFor('a')).getOrElse(() => []);
      expect(tracks.first, saved);
      expect(tracks.last.source, SubtitleSource.nearby);
      expect(tracks.last.label, 'Film.en.srt');
      expect(tracks.last.language, 'en');
    });

    test('loads captions; a broken file is a format failure', () async {
      final good = File('${dir.path}/good.srt')..writeAsStringSync(srt);
      final bad = File('${dir.path}/bad.srt')..writeAsStringSync('nonsense');
      SubtitleTrack at(File f) => SubtitleTrack(
        id: f.path,
        videoId: 'a',
        label: 'x',
        source: SubtitleSource.nearby,
        path: f.path,
      );

      final loaded = await repository.load(at(good));
      expect(
        loaded
            .getOrElse(() => throw 'failed')
            .textAt(const Duration(milliseconds: 1500)),
        'Hello',
      );
      expect(
        await repository.load(at(bad)),
        const Left(SubtitleFormatFailure()),
      );
      expect(
        await repository.load(at(File('${dir.path}/missing.srt'))),
        const Left(SubtitleStorageFailure()),
      );
    });
  });

  group('import', () {
    test('cancelled: nothing', () async {
      expect(await repository.importFromDevice('a'), const Right(null));
    });

    test('a good file is kept and chosen', () async {
      device.picked = (name: 'Film.ar.vtt', bytes: bytesOf('WEBVTT\n\n$srt'));
      final result = await repository.importFromDevice('a');
      final track = result.getOrElse(() => null)!;
      expect(track.source, SubtitleSource.imported);
      expect(track.language, 'ar');
      expect(track.path, endsWith('.vtt'));
      expect(await repository.selectedTrackId('a'), track.id);
      expect(await storage.tracks('a'), [track]);
    });

    test('a broken file is refused and not kept', () async {
      device.picked = (name: 'x.srt', bytes: bytesOf('not subtitles'));
      expect(
        await repository.importFromDevice('a'),
        const Left(SubtitleFormatFailure()),
      );
      expect(await storage.tracks('a'), isEmpty);
    });

    test('the picker failing is a failure, not a crash', () async {
      device.pickError = PlatformException(code: 'query_failed');
      expect(
        await repository.importFromDevice('a'),
        const Left(SubtitleStorageFailure()),
      );
    });
  });

  group('online', () {
    void stubSearch() => when(
      () => remote.search(
        query: any(named: 'query'),
        movieHash: any(named: 'movieHash'),
        imdbId: any(named: 'imdbId'),
        language: any(named: 'language'),
      ),
    ).thenAnswer((_) async => const SubtitleSearchResponse());

    test('searches by name and, when readable, by the file', () async {
      device.path = '/movies/Film.mkv';
      stubSearch();

      await repository.searchOnline('a', query: 'Film', language: 'en');
      expect(hashed, ['/movies/Film.mkv']);
      verify(
        () => remote.search(
          query: 'Film',
          movieHash: 'abcdef0123456789',
          language: 'en',
        ),
      ).called(1);
    });

    test('by IMDb id: only the id (no name, no file reading)', () async {
      device.path = '/movies/Film.mkv';
      stubSearch();

      await repository.searchOnline('a', imdbId: 133093, language: 'en');
      expect(hashed, isEmpty);
      verify(() => remote.search(imdbId: 133093, language: 'en')).called(1);
    });

    test('results: one per file, exact matches then most downloaded', () {
      final response = SubtitleSearchResponse.fromJson(
        jsonDecode(searchJson) as Map<String, dynamic>,
      );
      final results = SubtitleRepositoryImpl.mapSearchResponse(response);
      expect(results.map((r) => r.fileId), [300, 100, 101]);
      expect(results.first.matchesFile, isTrue);
      expect(results.first.title, '2019 - Other');
      expect(results[1].title, 'Film.2020.1080p');
      // Format from the file name; IMDb id from the film's details.
      expect(results.first.format, 'srt');
      expect(results[1].imdbId, 133093);
    });

    test('downloads once, then keeps the copy (no second download)', () async {
      when(() => remote.download(42)).thenAnswer(
        (_) async => OpenSubtitlesFile(
          bytes: bytesOf(srt),
          fileName: 'Film.srt',
          remaining: 9,
          resetsIn: '12 hours',
        ),
      );

      final first = (await repository.download(
        'a',
        online,
      )).getOrElse(() => throw 'failed');
      expect(first.fromCache, isFalse);
      expect(first.remaining, 9);
      expect(first.resetsIn, '12 hours');
      expect(first.track.source, SubtitleSource.downloaded);
      expect(first.track.remoteFileId, 42);
      expect(first.track.label, 'Film.2020.1080p');
      expect(await repository.selectedTrackId('a'), first.track.id);

      final second = (await repository.download(
        'a',
        online,
      )).getOrElse(() => throw 'failed');
      expect(second.fromCache, isTrue);
      expect(second.track, first.track);
      verify(() => remote.download(42)).called(1);
    });

    test('downloaded subtitles load offline (no network at all)', () async {
      when(() => remote.download(42)).thenAnswer(
        (_) async => OpenSubtitlesFile(bytes: bytesOf(srt), fileName: 'x.srt'),
      );
      await repository.download('a', online);

      // Offline from now on: every network call fails.
      when(() => remote.download(any()))
          .thenThrow(const OpenSubtitlesException(OpenSubtitlesError.network));
      final tracks = (await repository.tracksFor('a')).getOrElse(() => []);
      final timeline = (await repository.load(tracks.single))
          .getOrElse(() => throw 'failed');
      expect(timeline.textAt(const Duration(milliseconds: 1500)), 'Hello');
      // And asking again uses the kept copy, not the network.
      expect((await repository.download('a', online)).isRight(), isTrue);
    });

    test('a downloaded file that is not subtitles is not kept', () async {
      when(() => remote.download(42)).thenAnswer(
        (_) async => OpenSubtitlesFile(bytes: bytesOf('<html>error</html>')),
      );
      expect(
        await repository.download('a', online),
        const Left(SubtitleFormatFailure()),
      );
      expect(await storage.tracks('a'), isEmpty);
    });

    test('service errors become failures the screen can explain', () async {
      final cases = {
        const OpenSubtitlesException(OpenSubtitlesError.notConfigured):
            const SubtitleNotConfiguredFailure(),
        const OpenSubtitlesException(OpenSubtitlesError.network):
            const SubtitleNetworkFailure(),
        const OpenSubtitlesException(OpenSubtitlesError.unauthorized):
            const SubtitleAuthFailure(),
        const OpenSubtitlesException(OpenSubtitlesError.downloadNotAllowed):
            const SubtitleDownloadNotAllowedFailure(),
        const OpenSubtitlesException(
          OpenSubtitlesError.rateLimited,
          retryAfter: Duration(seconds: 3),
        ): const SubtitleRateLimitFailure(
          retryAfter: Duration(seconds: 3),
        ),
        const OpenSubtitlesException(
          OpenSubtitlesError.quotaExceeded,
          resetsIn: '5 hours',
        ): const SubtitleQuotaFailure(
          resetsIn: '5 hours',
        ),
        const OpenSubtitlesException(OpenSubtitlesError.server):
            const SubtitleServiceFailure(),
      };
      for (final MapEntry(key: error, value: failure) in cases.entries) {
        when(() => remote.download(42)).thenThrow(error);
        expect(await repository.download('a', online), Left(failure));
      }
    });
  });
}

const searchJson = '''
{
  "total_count": 3, "total_pages": 1, "page": 1,
  "data": [
    {
      "id": "1", "type": "subtitle",
      "attributes": {
        "language": "en", "release": "Film.2020.1080p",
        "download_count": 500, "hearing_impaired": false,
        "feature_details": {"title": "Film", "movie_name": "2020 - Film", "year": 2020, "imdb_id": 133093},
        "files": [
          {"file_id": 100, "file_name": "Film.cd1.srt", "cd_number": 1},
          {"file_id": 101, "file_name": "Film.cd2.srt", "cd_number": 2}
        ]
      }
    },
    {
      "id": "2", "type": "subtitle",
      "attributes": {
        "language": "en", "release": "",
        "download_count": 3, "moviehash_match": true,
        "feature_details": {"title": "Other", "movie_name": "2019 - Other"},
        "files": [{"file_id": 300, "file_name": "Other.srt"}]
      }
    },
    {
      "id": "3", "type": "subtitle",
      "attributes": {"language": "fr", "files": [{"file_id": 100}]}
    }
  ]
}
''';
