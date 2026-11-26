import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_api.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_config.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_models.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_query_interceptor.dart';

/// What went wrong talking to OpenSubtitles.
enum OpenSubtitlesError {
  notConfigured,
  network,

  /// The key was refused (401 on a search).
  unauthorized,

  /// A download was refused (401 on `/download`).
  downloadNotAllowed,
  rateLimited,
  quotaExceeded,
  server,
}

class OpenSubtitlesException implements Exception {
  const OpenSubtitlesException(
    this.error, {
    this.retryAfter,
    this.resetsIn,
    this.message,
  });

  final OpenSubtitlesError error;

  /// From a 429's `Retry-After`.
  final Duration? retryAfter;

  /// From a quota answer (e.g. "5 hours").
  final String? resetsIn;
  final String? message;

  @override
  String toString() => 'OpenSubtitlesException($error, $message)';
}

/// OpenSubtitles for the repository: search, then download (ask for a
/// link, fetch the file). Every failure is an [OpenSubtitlesException];
/// requests are spaced out to stay under the service's rate limit.
class OpenSubtitlesRemoteDataSource {
  OpenSubtitlesRemoteDataSource({
    required this.config,
    required this._api,
    required this._files,
  });

  /// The [Dio] for the API: base URL, the key and app name on every
  /// request, JSON.
  static Dio createDio(OpenSubtitlesConfig config) => Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Api-Key': config.apiKey,
        'User-Agent': config.userAgent,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(const OpenSubtitlesQueryInterceptor());

  /// The [Dio] for the files themselves (the links need no key).
  static Dio createFileDio(OpenSubtitlesConfig config) => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'User-Agent': config.userAgent},
      responseType: ResponseType.bytes,
    ),
  );

  final OpenSubtitlesConfig config;
  final OpenSubtitlesApi _api;
  final Dio _files;
  DateTime? _lastRequest;

  bool get isConfigured => config.isConfigured;

  Future<SubtitleSearchResponse> search({
    String? query,
    String? movieHash,
    int? imdbId,
    String? language,
  }) => _call(
    () => _api.search(
      query: query,
      movieHash: movieHash,
      imdbId: imdbId,
      languages: language,
    ),
  );

  /// The format downloads are asked in (the service converts others).
  static const String downloadFormat = 'srt';

  /// The official two steps: `POST /download` gives a short-lived link
  /// (search results never hold one), then the file is fetched from it.
  Future<OpenSubtitlesFile> download(int fileId) async {
    final link = await _call(
      () => _api.requestDownload(
        SubtitleDownloadRequest(fileId: fileId, subFormat: downloadFormat),
      ),
      download: true,
    );
    final response = await _call(
      () => _files.get<List<int>>(link.link),
      throttle: false, // a file server, not the API
      download: true,
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw const OpenSubtitlesException(
        OpenSubtitlesError.server,
        message: 'empty file',
      );
    }
    return OpenSubtitlesFile(
      bytes: Uint8List.fromList(data),
      fileName: link.fileName,
      remaining: link.remaining,
      resetsIn: link.resetTime,
    );
  }

  Future<T> _call<T>(
    Future<T> Function() request, {
    bool throttle = true,
    bool download = false,
  }) async {
    if (!isConfigured) {
      throw const OpenSubtitlesException(OpenSubtitlesError.notConfigured);
    }
    if (throttle) await _wait();
    try {
      return await request();
    } on DioException catch (e) {
      throw _map(e, download: download);
    } on TypeError {
      // An answer not shaped as documented (details stay out of messages).
      throw const OpenSubtitlesException(
        OpenSubtitlesError.server,
        message: 'unexpected response',
      );
    } on FormatException {
      throw const OpenSubtitlesException(
        OpenSubtitlesError.server,
        message: 'unexpected response',
      );
    }
  }

  Future<void> _wait() async {
    final last = _lastRequest;
    final now = DateTime.now();
    if (last != null) {
      final wait = config.minRequestInterval - now.difference(last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    _lastRequest = DateTime.now();
  }

  static OpenSubtitlesException _map(DioException e, {required bool download}) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const OpenSubtitlesException(OpenSubtitlesError.network);
      case DioExceptionType.badResponse:
        break;
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return e.error is OpenSubtitlesException
            ? e.error! as OpenSubtitlesException
            : OpenSubtitlesException(
                e.message == null || e.response == null
                    ? OpenSubtitlesError.network
                    : OpenSubtitlesError.server,
                message: e.message,
              );
    }
    final response = e.response;
    final status = response?.statusCode ?? 0;
    final body = response?.data;
    final message = body is Map ? body['message']?.toString() : null;
    return switch (status) {
      401 || 403 => OpenSubtitlesException(
        download
            ? OpenSubtitlesError.downloadNotAllowed
            : OpenSubtitlesError.unauthorized,
        message: message,
      ),
      406 => OpenSubtitlesException(
        OpenSubtitlesError.quotaExceeded,
        message: message,
        resetsIn: body is Map ? body['reset_time']?.toString() : null,
      ),
      429 => OpenSubtitlesException(
        OpenSubtitlesError.rateLimited,
        message: message,
        retryAfter: _retryAfter(response?.headers.value('retry-after')),
      ),
      _ => OpenSubtitlesException(
        OpenSubtitlesError.server,
        message: message ?? 'HTTP $status',
      ),
    };
  }

  static Duration? _retryAfter(String? value) {
    final seconds = int.tryParse(value?.trim() ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }
}

/// A downloaded file, and what's left of the day's allowance.
class OpenSubtitlesFile {
  const OpenSubtitlesFile({
    required this.bytes,
    this.fileName,
    this.remaining,
    this.resetsIn,
  });

  final Uint8List bytes;
  final String? fileName;

  /// Downloads left today (as the service counts them).
  final int? remaining;

  /// When the allowance resets (e.g. "5 hours").
  final String? resetsIn;
}
