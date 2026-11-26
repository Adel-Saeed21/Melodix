import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// What a [VideoEngine] is doing right now.
@immutable
class VideoEngineValue {
  const VideoEngineValue({
    this.isInitialized = false,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.bufferedTo = Duration.zero,
    this.size = Size.zero,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isCompleted = false,
  });

  final bool isInitialized;
  final Duration duration;
  final Duration position;

  /// How far ahead it's loaded.
  final Duration bufferedTo;

  /// The picture's size as shown (rotation applied); empty until known.
  final Size size;
  final bool isPlaying;
  final bool isBuffering;

  /// Played to the end.
  final bool isCompleted;

  /// Width / height; 16:9 until the size is known.
  double get aspectRatio => size.isEmpty ? 16 / 9 : size.width / size.height;

  VideoEngineValue copyWith({
    bool? isInitialized,
    Duration? duration,
    Duration? position,
    Duration? bufferedTo,
    Size? size,
    bool? isPlaying,
    bool? isBuffering,
    bool? isCompleted,
  }) => VideoEngineValue(
    isInitialized: isInitialized ?? this.isInitialized,
    duration: duration ?? this.duration,
    position: position ?? this.position,
    bufferedTo: bufferedTo ?? this.bufferedTo,
    size: size ?? this.size,
    isPlaying: isPlaying ?? this.isPlaying,
    isBuffering: isBuffering ?? this.isBuffering,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}

/// Plays one video. The app's own interface for it: the player logic and
/// the screens use only this, never a video library directly, so the
/// library can change (or be faked in tests) without touching them.
///
/// Listeners hear about every change (the position several times a
/// second).
abstract interface class VideoEngine
    implements ValueListenable<VideoEngineValue> {
  /// Opens the video. Throws if it can't be played.
  Future<void> initialize();

  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setSpeed(double speed);

  /// The picture. It can be shown in several places at once (the player,
  /// the small window).
  Widget buildView();

  /// Releases the video once no [buildView] widget is on screen any more
  /// (so a view on its way out never draws a released video). Safe to call
  /// twice.
  Future<void> dispose();
}

/// Makes the engine for a video's playback URI.
typedef VideoEngineFactory = VideoEngine Function(Uri uri);
