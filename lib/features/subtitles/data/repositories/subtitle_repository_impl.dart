import 'dart:developer' as developer;
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_models.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_remote_data_source.dart';
import 'package:melodix/features/subtitles/data/datasources/subtitle_device_source.dart';
import 'package:melodix/features/subtitles/data/datasources/subtitle_local_storage.dart';
import 'package:melodix/features/subtitles/data/parsing/movie_hash.dart';
import 'package:melodix/features/subtitles/data/parsing/subtitle_parser.dart';
import 'package:melodix/features/subtitles/domain/entities/online_subtitle.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_cue.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_download.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_failure.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_track.dart';
import 'package:melodix/features/subtitles/domain/repositories/subtitle_repository.dart';
import 'package:path/path.dart' as p;

class SubtitleRepositoryImpl implements SubtitleRepository {
  SubtitleRepositoryImpl({
    required this._storage,
    required this._device,
    required this._remote,
    required this._playbackUri,
    this._parser = const SubtitleParser(),
    Future<String?> Function(File file)? hash,
  }) : _hash = hash ?? openSubtitlesHash;

  final SubtitleLocalStorage _storage;
  final SubtitleDeviceSource _device;
  final OpenSubtitlesRemoteDataSource _remote;

  /// The video's playback URI (to find its file).
  final Future<Uri?> Function(String videoId) _playbackUri;
  final SubtitleParser _parser;
  final Future<String?> Function(File file) _hash;

  @override
  Future<Either<SubtitleFailure, List<SubtitleTrack>>> tracksFor(
    String videoId,
  ) async {
    try {
      final saved = await _storage.tracks(videoId);
      final nearby = await _nearby(videoId);
      return Right([...saved, ...nearby]);
    } on FileSystemException catch (e, stack) {
      _log('Reading saved subtitles failed', e, stack);
      return const Left(SubtitleStorageFailure());
    }
  }

  Future<List<SubtitleTrack>> _nearby(String videoId) async {
    final path = await _videoPath(videoId);
    if (path == null) return const [];
    return [
      for (final file in await _device.nearbySubtitles(path))
        SubtitleTrack(
          id: 'nearby:${p.basename(file.path)}',
          videoId: videoId,
          label: p.basename(file.path),
          source: SubtitleSource.nearby,
          path: file.path,
          language: _languageFromName(file.path),
        ),
    ];
  }

  Future<String?> _videoPath(String videoId) async {
    final uri = await _playbackUri(videoId);
    return uri == null ? null : _device.videoPath(uri);
  }

  @override
  Future<Either<SubtitleFailure, SubtitleTimeline>> load(
    SubtitleTrack track,
  ) async {
    try {
      final bytes = await File(track.path).readAsBytes();
      return Right(_parser.parseBytes(bytes));
    } on SubtitleFormatException {
      return const Left(SubtitleFormatFailure());
    } on FileSystemException catch (e, stack) {
      _log('Reading a subtitle file failed', e, stack);
      return const Left(SubtitleStorageFailure());
    }
  }

  @override
  Future<String?> selectedTrackId(String videoId) async {
    try {
      return await _storage.selected(videoId);
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> setSelectedTrackId(String videoId, String? trackId) async {
    try {
      await _storage.setSelected(videoId, trackId);
    } on FileSystemException catch (e, stack) {
      // Not remembered; the choice still applies now.
      _log('Saving the subtitle choice failed', e, stack);
    }
  }

  @override
  bool get canImport => _device.canPick;

  @override
  Future<Either<SubtitleFailure, SubtitleTrack?>> importFromDevice(
    String videoId,
  ) async {
    final DeviceSubtitleFile? picked;
    try {
      picked = await _device.pick();
    } on PlatformException catch (e, stack) {
      _log('Picking a subtitle file failed', e, stack);
      return const Left(SubtitleStorageFailure());
    }
    if (picked == null) return const Right(null);
    final extension = p.extension(picked.name).toLowerCase();
    try {
      // Checked before keeping it: a broken file never becomes a track.
      _parser.parseBytes(picked.bytes);
      final track = await _storage.save(
        videoId: videoId,
        id: 'imported:${picked.name}',
        label: picked.name,
        source: SubtitleSource.imported,
        extension: extension == '.vtt' ? 'vtt' : 'srt',
        bytes: picked.bytes,
        language: _languageFromName(picked.name),
      );
      await setSelectedTrackId(videoId, track.id);
      return Right(track);
    } on SubtitleFormatException {
      return const Left(SubtitleFormatFailure());
    } on FileSystemException catch (e, stack) {
      _log('Saving an imported subtitle failed', e, stack);
      return const Left(SubtitleStorageFailure());
    }
  }

  @override
  bool get canSearchOnline => _remote.isConfigured;

  @override
  Future<Either<SubtitleFailure, List<OnlineSubtitle>>> searchOnline(
    String videoId, {
    String? query,
    int? imdbId,
    String? language,
  }) async {
    try {
      // By IMDb id: exact on its own. Otherwise the name, plus the file's
      // fingerprint when the file can be read (exact matches first).
      String? hash;
      if (imdbId == null) {
        final path = await _videoPath(videoId);
        hash = path == null ? null : await _hash(File(path));
      }
      final response = await _remote.search(
        query: imdbId == null ? query : null,
        movieHash: hash,
        imdbId: imdbId,
        language: language,
      );
      return Right(mapSearchResponse(response));
    } on OpenSubtitlesException catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<SubtitleFailure, SubtitleDownload>> download(
    String videoId,
    OnlineSubtitle subtitle,
  ) async {
    try {
      // Already kept: no second download (and no allowance spent).
      final kept = await _storage.downloaded(videoId, subtitle.fileId);
      if (kept != null) {
        await setSelectedTrackId(videoId, kept.id);
        return Right(SubtitleDownload(track: kept, fromCache: true));
      }
      final file = await _remote.download(subtitle.fileId);
      // Never keep something that isn't subtitles (e.g. an error page).
      _parser.parseBytes(file.bytes);
      final name = file.fileName ?? '';
      final track = await _storage.save(
        videoId: videoId,
        id: 'downloaded:${subtitle.fileId}',
        label: subtitle.title,
        source: SubtitleSource.downloaded,
        extension: p.extension(name).toLowerCase() == '.vtt' ? 'vtt' : 'srt',
        bytes: file.bytes,
        language: subtitle.language,
        remoteFileId: subtitle.fileId,
      );
      await setSelectedTrackId(videoId, track.id);
      return Right(
        SubtitleDownload(
          track: track,
          remaining: file.remaining,
          resetsIn: file.resetsIn,
        ),
      );
    } on OpenSubtitlesException catch (e) {
      return Left(_failure(e));
    } on SubtitleFormatException {
      return const Left(SubtitleFormatFailure());
    } on FileSystemException catch (e, stack) {
      _log('Saving a downloaded subtitle failed', e, stack);
      return const Left(SubtitleStorageFailure());
    }
  }

  /// One result per file (multi-part releases have a file per part);
  /// results made for this exact file first, then the most downloaded.
  static List<OnlineSubtitle> mapSearchResponse(
    SubtitleSearchResponse response,
  ) {
    final results = <OnlineSubtitle>[];
    final seen = <int>{};
    for (final item in response.data) {
      final a = item.attributes;
      final title = _firstNonEmpty([
        a.release,
        a.featureDetails?.movieName,
        a.featureDetails?.title,
      ]);
      for (final file in a.files) {
        if (!seen.add(file.fileId)) continue;
        results.add(
          OnlineSubtitle(
            fileId: file.fileId,
            title: title ?? file.fileName ?? 'Subtitle ${file.fileId}',
            language: a.language ?? '',
            fileName: file.fileName,
            downloadCount: a.downloadCount,
            hearingImpaired: a.hearingImpaired,
            matchesFile: a.movieHashMatch,
            format: _format(file.fileName),
            imdbId: a.featureDetails?.imdbId,
          ),
        );
      }
    }
    results.sort((x, y) {
      if (x.matchesFile != y.matchesFile) return x.matchesFile ? -1 : 1;
      return y.downloadCount.compareTo(x.downloadCount);
    });
    return results;
  }

  static SubtitleFailure _failure(OpenSubtitlesException e) =>
      switch (e.error) {
        OpenSubtitlesError.notConfigured =>
          const SubtitleNotConfiguredFailure(),
        OpenSubtitlesError.network => const SubtitleNetworkFailure(),
        OpenSubtitlesError.unauthorized => const SubtitleAuthFailure(),
        OpenSubtitlesError.downloadNotAllowed =>
          const SubtitleDownloadNotAllowedFailure(),
        OpenSubtitlesError.rateLimited => SubtitleRateLimitFailure(
          retryAfter: e.retryAfter,
        ),
        OpenSubtitlesError.quotaExceeded => SubtitleQuotaFailure(
          resetsIn: e.resetsIn,
        ),
        OpenSubtitlesError.server => const SubtitleServiceFailure(),
      };

  /// "Film.en.srt" → "srt"; "srt" when the name has no extension.
  static String _format(String? fileName) {
    final ext = p.extension(fileName ?? '').replaceFirst('.', '').toLowerCase();
    return ext.isEmpty || ext.length > 4 ? 'srt' : ext;
  }

  /// "Film.en.srt" → "en" (a two- or three-letter part before the
  /// extension).
  static String? _languageFromName(String name) {
    final parts = p.basenameWithoutExtension(name).split('.');
    if (parts.length < 2) return null;
    final last = parts.last.toLowerCase();
    return RegExp(r'^[a-z]{2,3}$').hasMatch(last) ? last : null;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static void _log(String message, Object error, StackTrace stack) => developer
      .log(message, name: 'melodix.subtitles', error: error, stackTrace: stack);
}
