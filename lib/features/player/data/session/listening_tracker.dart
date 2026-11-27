import 'dart:async';
import 'dart:developer' as developer;

import 'package:melodix/features/player/domain/repositories/play_recorder.dart';

/// Turns what the player reports into plays and listening time, counting
/// only what is really heard.
///
/// The player calls [update] on every position and state change with the
/// current song, its position, and whether it is really playing (not
/// paused, buffering or finished). From that:
/// * **listening time** is the position moving forward while playing. A
///   paused or buffering player doesn't move, and the player reports every
///   seek ([seeked]), so jumps never count;
/// * **a play** is counted once per listen ("cycle"), when that listen
///   reaches [thresholdFor] the song: 30 s, or half of a song shorter than
///   a minute. Skipping or stopping before that counts nothing;
/// * **a new cycle** starts with a new queue, another song, the song
///   starting over by itself (repeat one, or a one-song queue repeating:
///   the position jumps back with no seek), or a deliberate restart
///   ([restarted]);
/// * **time is saved** in batches of [flushEvery], and whenever playback
///   stops, the song changes or the queue changes, so a killed app loses at
///   most [flushEvery] of listening.
///
/// Times are in song time (at 2× speed a minute of song takes 30 s).
class ListeningTracker {
  ListeningTracker(
    this._recorder, {
    this.flushEvery = const Duration(seconds: 10),
  });

  final PlayRecorder _recorder;

  /// Listening is saved at least this often while playing.
  final Duration flushEvery;

  /// A listen counts as a play after this much (see [thresholdFor]).
  static const Duration playThreshold = Duration(seconds: 30);

  /// Songs shorter than this count after half their length.
  static const Duration shortSong = Duration(seconds: 60);

  /// A jump back by more than this, with no seek reported, is the song
  /// starting over by itself.
  static const Duration _loopTolerance = Duration(seconds: 1);

  /// How much of a song of [length] makes a play.
  static Duration thresholdFor(Duration length) =>
      length > Duration.zero && length < shortSong
      ? length ~/ 2
      : playThreshold;

  /// Bumped for each new queue: the same song in a new queue is a new
  /// listen.
  int _queue = 0;

  /// The current listen: which song (in which queue) and how far it got.
  String? _key;
  int? _songId;
  Duration _length = Duration.zero;
  Duration _cycle = Duration.zero;
  bool _counted = false;

  /// The position at the last report while really playing; null when the
  /// next report can't be compared (paused, after a seek, a new song).
  Duration? _last;

  /// Heard but not saved yet (for [_songId]).
  Duration _unsaved = Duration.zero;

  /// A new queue starts: what was heard so far is saved.
  void newQueue() {
    _save();
    _queue++;
    _key = null;
    _songId = null;
    _last = null;
  }

  /// A restored session continues a listen that was [position] in: it
  /// counts as heard towards the play (not as new listening time, already
  /// saved before the app closed), so it isn't counted again or started
  /// over.
  void resume({
    required int songId,
    required Duration length,
    required Duration position,
  }) {
    _start(songId, length);
    final threshold = thresholdFor(length);
    _counted = position >= threshold;
    _cycle = _counted ? threshold : position;
  }

  /// The user moved to another point of the song: the jump isn't heard.
  void seeked() => _last = null;

  /// The song starts over on purpose (Next on repeat one, Previous after a
  /// few seconds): a new listen.
  void restarted() {
    _last = null;
    _newCycle();
  }

  /// The player is busy changing songs or the queue: nothing is compared
  /// across that, and what was heard is saved.
  void interrupted() {
    _last = null;
    _save();
  }

  /// The player's latest state: [songId] (of [length]) is current, at
  /// [position], and [listening] if it is really playing.
  void update({
    required int songId,
    required Duration length,
    required Duration position,
    required bool listening,
  }) {
    if ('$_queue:$songId' != _key) _start(songId, length);
    final last = _last;
    if (last != null) {
      final moved = position - last;
      if (moved > Duration.zero) {
        _heard(moved);
      } else if (moved < -_loopTolerance) {
        _newCycle(); // the song started over by itself
      }
    }
    _last = listening ? position : null;
    if (!listening) _save();
  }

  /// Saves what was heard and not saved yet.
  void flush() => _save();

  void _start(int songId, Duration length) {
    _save(); // the previous song's last seconds
    _key = '$_queue:$songId';
    _songId = songId;
    _length = length;
    _last = null;
    _newCycle();
  }

  void _newCycle() {
    _cycle = Duration.zero;
    _counted = false;
  }

  void _heard(Duration heard) {
    final songId = _songId;
    if (songId == null) return;
    _cycle += heard;
    _unsaved += heard;
    if (!_counted && _cycle >= thresholdFor(_length)) {
      _counted = true;
      _report(_recorder.recordPlay(songId));
    }
    if (_unsaved >= flushEvery) _save();
  }

  void _save() {
    final songId = _songId;
    final heard = _unsaved;
    if (songId == null || heard <= Duration.zero) return;
    _unsaved = Duration.zero;
    _report(_recorder.addListening(songId, heard));
  }

  /// Saving never stops playback: a failed write is logged and dropped.
  static void _report(Future<void> write) => unawaited(
    write.catchError(
      (Object e, StackTrace stack) => developer.log(
        'Listening not saved',
        name: 'melodix.listening',
        error: e,
        stackTrace: stack,
      ),
    ),
  );
}
