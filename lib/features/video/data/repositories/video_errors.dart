import 'dart:developer' as developer;

/// User-facing messages for video library failures (like the music
/// library's `LibraryErrors`).
abstract final class VideoErrors {
  static const String sync = 'Could not read your videos';
  static const String write = 'Could not save your change';
  static const String delete = 'Could not delete the videos';
  static const String permission = 'Allow access to your videos to see them';
}

/// Logs a video library problem (shown in the developer console).
void logVideoProblem(String message, [Object? error, StackTrace? stack]) =>
    developer.log(
      message,
      name: 'melodix.video_library',
      error: error,
      stackTrace: stack,
    );
