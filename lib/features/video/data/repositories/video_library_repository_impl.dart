import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:melodix/core/database/video_local_storage.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:melodix/core/service/video_service.dart';
import 'package:melodix/core/utils/lru_cache.dart';
import 'package:melodix/core/utils/single_flight.dart';
import 'package:melodix/features/music_library/domain/entities/library_permission.dart';
import 'package:melodix/features/video/data/mappers/video_mapper.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/entities/video_library_changes.dart';
import 'package:melodix/features/video/domain/repositories/video_library_repository.dart';

/// User-facing messages for video library failures.
abstract final class VideoErrors {
  static const String sync = 'Could not read your videos';
  static const String write = 'Could not save your change';
  static const String permission = 'Allow access to your videos to see them';
}

class VideoLibraryRepositoryImpl implements VideoLibraryRepository {
  VideoLibraryRepositoryImpl({
    required this._service,
    required this._storage,
    int thumbnailCacheSize = 300,
  }) : _thumbnails = LruCache(capacity: thumbnailCacheSize);

  final VideoService _service;
  final VideoLocalStorage _storage;

  /// Concurrent syncs share one scan.
  final SingleFlight<Either<Failure, VideoLibraryChanges>> _flight =
      SingleFlight();

  /// Recently loaded thumbnails, keyed by "videoId:size". Null values
  /// remember videos without one so they aren't asked for again.
  final LruCache<String, Uint8List?> _thumbnails;

  /// Loads in progress, so the same thumbnail asked for twice at once
  /// reads the device once.
  final Map<String, Future<Uint8List?>> _loading = {};

  @override
  Future<LibraryPermission> checkPermission() async =>
      _toPermission(await _service.permissionStatus());

  @override
  Future<LibraryPermission> requestPermission() async =>
      _toPermission(await _service.requestPermission());

  @override
  Future<Either<Failure, VideoLibraryChanges>> syncLibrary() =>
      _flight.run(_sync);

  Future<Either<Failure, VideoLibraryChanges>> _sync() async {
    try {
      final scan = await _service.scan();
      final saved = await _storage.syncVideos(
        scan.videos,
        // Only the device's own count of 0 may empty a saved library.
        confirmedEmpty: scan.deviceCount == 0,
      );
      return Right(
        VideoLibraryChanges(
          added: saved.added,
          updated: saved.updated,
          removed: saved.removed,
          total: saved.total,
        ),
      );
    } on MediaPermissionException catch (e) {
      return Left(
        PermissionFailure(
          VideoErrors.permission,
          permanentlyDenied: e.permanentlyDenied,
        ),
      );
    } on MediaQueryException catch (e, stack) {
      _log(
        'Video sync stopped, library left unchanged: ${e.message}',
        e,
        stack,
      );
      return const Left(LibraryFailure(VideoErrors.sync));
    } catch (e, stack) {
      _log('Video sync failed, library left unchanged', e, stack);
      return const Left(LibraryFailure(VideoErrors.sync));
    }
  }

  @override
  Stream<List<Video>> watchVideos() =>
      _storage.watchAllVideos().map(VideoMapper.toEntities);

  @override
  Stream<List<Video>> watchFavoriteVideos() =>
      _storage.watchFavoriteVideos().map(VideoMapper.toEntities);

  @override
  Future<Either<Failure, bool>> toggleFavorite(String videoId) async {
    try {
      return Right(await _storage.toggleFavorite(videoId));
    } catch (e, stack) {
      _log('Could not toggle a video favourite', e, stack);
      return const Left(LibraryFailure(VideoErrors.write));
    }
  }

  @override
  FutureOr<Uint8List?> thumbnail(String videoId, {int size = 300}) {
    final key = '$videoId:$size';
    if (_thumbnails.containsKey(key)) return _thumbnails.get(key);
    // Block body on purpose: `remove` returns this very future, and
    // whenComplete would wait for a returned future, i.e. for itself.
    return _loading[key] ??= _loadThumbnail(key, videoId, size).whenComplete(
      () {
        _loading.remove(key);
      },
    );
  }

  @override
  ({Uint8List? bytes})? cachedThumbnail(String videoId, {int size = 300}) {
    final key = '$videoId:$size';
    return _thumbnails.containsKey(key) ? (bytes: _thumbnails.get(key)) : null;
  }

  Future<Uint8List?> _loadThumbnail(
    String key,
    String videoId,
    int size,
  ) async {
    final Uint8List? bytes;
    try {
      bytes = await _service.thumbnail(videoId, size: size);
    } catch (_) {
      return null; // Not cached: e.g. no permission yet, retried later.
    }
    _thumbnails.put(key, bytes);
    return bytes;
  }

  @override
  Future<void> recordPlay(String videoId) async {
    try {
      await _storage.recordPlay(videoId);
    } catch (e, stack) {
      _log('Could not count a video play', e, stack);
    }
  }

  @override
  Future<void> savePosition(String videoId, Duration position) async {
    try {
      await _storage.savePlaybackPosition(videoId, position);
    } catch (e, stack) {
      _log('Could not save where a video stopped', e, stack);
    }
  }

  @override
  Future<Uri?> playbackUri(String videoId) async {
    try {
      return await _service.playbackUri(videoId);
    } catch (e, stack) {
      _log('No playback URI for a video', e, stack);
      return null;
    }
  }

  static LibraryPermission _toPermission(MediaPermissionStatus status) =>
      switch (status) {
        MediaPermissionStatus.granted => LibraryPermission.granted,
        MediaPermissionStatus.denied => LibraryPermission.denied,
        MediaPermissionStatus.permanentlyDenied =>
          LibraryPermission.permanentlyDenied,
      };

  static void _log(String message, [Object? error, StackTrace? stack]) =>
      developer.log(
        message,
        name: 'melodix.video_library',
        error: error,
        stackTrace: stack,
      );
}
