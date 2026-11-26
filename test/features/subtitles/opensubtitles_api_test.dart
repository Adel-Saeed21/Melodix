import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_api.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_config.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_models.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_remote_data_source.dart';

/// Answers requests from a table instead of the network, and records them.
class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.answer);

  final ResponseBody Function(RequestOptions options) answer;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return answer(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(Object body, int status, {Map<String, String>? headers}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final e in (headers ?? {}).entries) e.key: [e.value],
      },
    );

void main() {
  const config = OpenSubtitlesConfig(
    apiKey: 'test-key',
    minRequestInterval: Duration.zero,
  );

  ({OpenSubtitlesRemoteDataSource source, StubAdapter api, StubAdapter files})
  build(
    ResponseBody Function(RequestOptions) api, {
    ResponseBody Function(RequestOptions)? files,
    OpenSubtitlesConfig cfg = config,
  }) {
    final apiAdapter = StubAdapter(api);
    final fileAdapter = StubAdapter(
      files ?? (_) => ResponseBody.fromString('', 200),
    );
    final apiDio = OpenSubtitlesRemoteDataSource.createDio(cfg)
      ..httpClientAdapter = apiAdapter;
    final fileDio = OpenSubtitlesRemoteDataSource.createFileDio(cfg)
      ..httpClientAdapter = fileAdapter;
    return (
      source: OpenSubtitlesRemoteDataSource(
        config: cfg,
        api: OpenSubtitlesApi(apiDio),
        files: fileDio,
      ),
      api: apiAdapter,
      files: fileAdapter,
    );
  }

  group('models', () {
    test('a search answer, with missing fields defaulted', () {
      final response = SubtitleSearchResponse.fromJson({
        'total_count': 1,
        'data': [
          {
            'id': '9',
            'attributes': {
              'language': 'ar',
              'download_count': 12,
              'hearing_impaired': true,
              'feature_details': {'title': 'Film', 'year': 2020},
              'files': [
                {'file_id': 5, 'file_name': 'f.srt', 'cd_number': 1},
              ],
              'unknown_field': 'ignored',
            },
          },
        ],
      });
      final a = response.data.single.attributes;
      expect(response.totalCount, 1);
      expect(response.page, 1);
      expect(a.language, 'ar');
      expect(a.downloadCount, 12);
      expect(a.hearingImpaired, isTrue);
      expect(a.movieHashMatch, isFalse);
      expect(a.featureDetails?.year, 2020);
      expect(
        a.files.single,
        const SubtitleFileModel(fileId: 5, fileName: 'f.srt', cdNumber: 1),
      );
    });

    test('a download answer, and the request body', () {
      final r = SubtitleDownloadResponse.fromJson({
        'link': 'https://dl/x.srt',
        'file_name': 'x.srt',
        'remaining': 4,
        'reset_time': '23 hours',
      });
      expect(r.link, 'https://dl/x.srt');
      expect(r.remaining, 4);
      expect(r.resetTime, '23 hours');
      expect(const SubtitleDownloadRequest(fileId: 7).toJson(), {'file_id': 7});
    });

    test('a malformed answer throws while parsing', () {
      expect(
        () => SubtitleSearchItem.fromJson({'id': 1, 'attributes': 'x'}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('requests', () {
    test('search sends the key, the app name and the query', () async {
      final t = build((_) => json({'total_count': 0, 'data': []}, 200));
      final response = await t.source.search(
        query: 'Film',
        movieHash: 'abc',
        language: 'en',
      );
      expect(response.data, isEmpty);
      final request = t.api.requests.single;
      expect(
        request.uri.toString(),
        startsWith(OpenSubtitlesConfig.defaultBaseUrl),
      );
      expect(request.uri.path, endsWith('/subtitles'));
      expect(request.uri.queryParameters, {
        'query': 'film',
        'moviehash': 'abc',
        'languages': 'en',
      });
      expect(request.headers['Api-Key'], 'test-key');
      expect(request.headers['User-Agent'], 'Melodix v1.0');
    });

    test('download: asks for a link, then fetches the file', () async {
      final t = build(
        (_) => json({
          'link': 'https://files.example/x.srt',
          'file_name': 'x.srt',
        }, 200),
        files: (_) => ResponseBody.fromBytes(utf8.encode('1\n...'), 200),
      );
      final file = await t.source.download(42);
      expect(utf8.decode(file.bytes), '1\n...');
      expect(file.fileName, 'x.srt');
      expect(t.api.requests.single.method, 'POST');
      expect(t.api.requests.single.uri.path, endsWith('/download'));
      // The id, and SRT asked for (the service converts other formats).
      expect(t.api.requests.single.data, {'file_id': 42, 'sub_format': 'srt'});
      expect(t.api.requests.single.headers['Api-Key'], 'test-key');
      expect(
        t.files.requests.single.uri.toString(),
        'https://files.example/x.srt',
      );
      expect(t.files.requests.single.headers.containsKey('Api-Key'), isFalse);
    });

    test('download: what is left of the daily allowance', () async {
      final t = build(
        (_) => json({
          'link': 'https://files.example/x.srt',
          'remaining': 7,
          'requests': 3,
          'reset_time': '10 hours',
        }, 200),
        files: (_) => ResponseBody.fromBytes(utf8.encode('x'), 200),
      );
      final file = await t.source.download(1);
      expect(file.remaining, 7);
      expect(file.resetsIn, '10 hours');
    });

    test('the query is written the way the service wants it', () async {
      // Unsorted, mixed case or %20 spaces get a 301 instead of results.
      final t = build((_) => json({'data': []}, 200));
      await t.source.search(
        query: 'The Matrix',
        movieHash: 'ABC123',
        language: 'pt-PT',
      );
      expect(
        t.api.requests.single.uri.query,
        'languages=pt-pt&moviehash=abc123&query=the+matrix',
      );
    });

    test('search by IMDb id sends imdb_id', () async {
      final t = build((_) => json({'data': []}, 200));
      await t.source.search(imdbId: 133093, language: 'en');
      expect(t.api.requests.single.uri.queryParameters, {
        'imdb_id': '133093',
        'languages': 'en',
      });
    });
  });

  group('errors', () {
    Future<OpenSubtitlesException> errorFor(ResponseBody body) async {
      final t = build((_) => body);
      try {
        await t.source.search(query: 'x');
      } on OpenSubtitlesException catch (e) {
        return e;
      }
      fail('no error');
    }

    Future<OpenSubtitlesException> downloadErrorFor(ResponseBody body) async {
      final t = build((_) => body);
      try {
        await t.source.download(1);
      } on OpenSubtitlesException catch (e) {
        return e;
      }
      fail('no error');
    }

    test('401 on a download: not allowed (not "invalid key")', () async {
      final e = await downloadErrorFor(json({'message': 'nope'}, 401));
      expect(e.error, OpenSubtitlesError.downloadNotAllowed);
    });

    test('429 on a download: rate limited', () async {
      final e = await downloadErrorFor(
        json({}, 429, headers: {'retry-after': '10'}),
      );
      expect(e.error, OpenSubtitlesError.rateLimited);
      expect(e.retryAfter, const Duration(seconds: 10));
    });

    test('the key never shows in errors or the config', () async {
      final e = await errorFor(json({'message': 'Invalid key'}, 401));
      expect(e.toString(), isNot(contains('test-key')));
      expect(config.toString(), isNot(contains('test-key')));
      expect(config.toString(), contains('<set>'));
    });

    test('401: unauthorized', () async {
      final e = await errorFor(json({'message': 'Invalid key'}, 401));
      expect(e.error, OpenSubtitlesError.unauthorized);
      expect(e.message, 'Invalid key');
    });

    test('429: rate limited, with Retry-After', () async {
      final e = await errorFor(
        json({'message': 'Slow down'}, 429, headers: {'retry-after': '3'}),
      );
      expect(e.error, OpenSubtitlesError.rateLimited);
      expect(e.retryAfter, const Duration(seconds: 3));
    });

    test('406: daily quota, with when it resets', () async {
      final e = await errorFor(
        json({'message': 'quota', 'reset_time': '5 hours'}, 406),
      );
      expect(e.error, OpenSubtitlesError.quotaExceeded);
      expect(e.resetsIn, '5 hours');
    });

    test('500 and odd answers: server', () async {
      expect((await errorFor(json({}, 503))).error, OpenSubtitlesError.server);
      expect(
        (await errorFor(json({'data': 'not a list'}, 200))).error,
        OpenSubtitlesError.server,
      );
    });

    test('no connection: network', () async {
      final t = build(
        (o) => throw DioException.connectionError(
          requestOptions: o,
          reason: 'offline',
        ),
      );
      await expectLater(
        t.source.search(query: 'x'),
        throwsA(
          isA<OpenSubtitlesException>().having(
            (e) => e.error,
            'error',
            OpenSubtitlesError.network,
          ),
        ),
      );
    });

    test('no API key: nothing is sent', () async {
      final t = build(
        (_) => json({}, 200),
        cfg: const OpenSubtitlesConfig(apiKey: ''),
      );
      expect(t.source.isConfigured, isFalse);
      await expectLater(
        t.source.search(query: 'x'),
        throwsA(
          isA<OpenSubtitlesException>().having(
            (e) => e.error,
            'error',
            OpenSubtitlesError.notConfigured,
          ),
        ),
      );
      expect(t.api.requests, isEmpty);
    });
  });
}
