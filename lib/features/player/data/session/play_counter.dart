import 'dart:async';

import 'package:melodix/features/player/domain/repositories/play_recorder.dart';

/// Counts one play each time a song starts, and only once per start: the
/// same song reported again (a pause and resume, a seek) isn't counted
/// again, but playing it again in a new queue is.
class PlayCounter {
  PlayCounter(this._recorder);

  final PlayRecorder _recorder;

  /// Bumped for each new queue, so the same index in a new queue counts.
  int _queueVersion = 0;
  String? _lastCounted;

  /// A new queue starts.
  void newQueue() => _queueVersion++;

  /// The song at [logical] is already counted (e.g. restored after a
  /// restart: resuming it isn't a new play).
  void alreadyCounted(int logical) => _lastCounted = '$_queueVersion:$logical';

  /// The song at [logical] (with [songId]) is playing: counts it if this
  /// start wasn't counted yet.
  void playing({required int logical, required int songId}) {
    final key = '$_queueVersion:$logical';
    if (key == _lastCounted) return;
    _lastCounted = key;
    unawaited(_recorder.recordPlay(songId));
  }
}
