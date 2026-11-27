import 'dart:developer' as developer;

import 'package:melodix/core/errors/error_messages.dart';

/// User-facing messages for video library failures (like the music
/// library's `LibraryErrors`).
abstract final class VideoErrors {
  static const String sync = ErrorMessages.videosSync;
  static const String write = ErrorMessages.write;
  static const String delete = ErrorMessages.videosDelete;
  static const String permission = ErrorMessages.videosPermission;
}

/// Logs a video library problem (shown in the developer console).
void logVideoProblem(String message, [Object? error, StackTrace? stack]) =>
    developer.log(
      message,
      name: 'melodix.video_library',
      error: error,
      stackTrace: stack,
    );
