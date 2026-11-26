import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/domain/entities/library_permission.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/entities/video_library_changes.dart';

/// The videos on the device and what the user does with them.
abstract interface class VideoLibraryRepository {
  /// Current access to the videos, without asking.
  Future<LibraryPermission> checkPermission();

  /// Asks the user for access (call from a button, never in the background).
  Future<LibraryPermission> requestPermission();

  /// Brings the saved library in line with the device. Never asks for
  /// permission (fails with [PermissionFailure] instead) and never changes
  /// the saved library when the device can't be read completely
  /// ([LibraryFailure]). Concurrent calls share one scan.
  Future<Either<Failure, VideoLibraryChanges>> syncLibrary();

  /// All videos, newest first, now and on every change.
  Stream<List<Video>> watchVideos();

  /// The favourite videos, newest first, now and on every change.
  Stream<List<Video>> watchFavoriteVideos();

  /// Flips the video's favourite flag; returns the new value.
  Future<Either<Failure, bool>> toggleFavorite(String videoId);

  /// The video's thumbnail at about [size] px, or null if it has none.
  /// Cached: a cached answer comes back synchronously, and concurrent
  /// requests for the same thumbnail share one load.
  FutureOr<Uint8List?> thumbnail(String videoId, {int size = 300});

  /// The thumbnail if it's in memory already, without loading: null when
  /// not cached; a record (whose bytes may be null: none) when it is.
  ({Uint8List? bytes})? cachedThumbnail(String videoId, {int size = 300});

  /// Counts a play and stamps when it happened. Never throws (a lost
  /// count must not interrupt the video).
  Future<void> recordPlay(String videoId);

  /// Remembers where playback stopped, to resume there; near the end it's
  /// cleared (the video counts as watched). Never throws.
  Future<void> savePosition(String videoId, Duration position);

  /// What the video player should open (a `content://` URI on Android), or
  /// null if the video is gone.
  Future<Uri?> playbackUri(String videoId);
}
