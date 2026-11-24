import 'dart:async';

/// Decides between the app's two players: music and video. Only one
/// soundtrack at a time.
///
/// * A video about to play calls [videoStarting]: the music pauses.
/// * Music starting is announced on [musicStarted]: the video pauses.
///
/// One place for the rule, instead of each player knowing the other.
class PlaybackCoordinator {
  PlaybackCoordinator({
    required this._pauseMusic,
    required Stream<bool> musicPlaying,
  }) : musicStarted = musicPlaying
           .distinct()
           .where((playing) => playing)
           .map((_) {})
           .asBroadcastStream();

  final Future<void> Function() _pauseMusic;

  /// Fires each time music starts playing.
  final Stream<void> musicStarted;

  Future<void> videoStarting() => _pauseMusic();
}
