import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:melodix/features/player/data/queue/pause_requests.dart';
import 'package:melodix/features/player/data/queue/playback_queue.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';

/// The few songs just_audio holds at a time: a window of the queue around
/// the current song ([behind] songs before it, [ahead] after), in play
/// order. The window slides as playback moves, so a queue of 10,000 songs
/// costs the same as an album. Queues that fit in the window are loaded
/// whole.
///
/// Every loaded item is tagged with a [Slot] (its logical index and play
/// position), so the player's position maps back to the logical queue
/// without relying on window offsets. Shuffle and "repeat all" work on the
/// whole [queue]; just_audio's shuffle is never used, and its loop mode is
/// only "one", or "all" when the whole queue is loaded.
///
/// Not thread-safe on its own: the repository calls the changing methods
/// one at a time (its serial runner).
class LoadedWindow {
  LoadedWindow(
    this._player, {
    required this.ahead,
    required this.behind,
    required this._repeat,
    required this._pauses,
    required this._onChanged,
    required this._onLoadFailed,
    required this._onCurrentChanged,
  }) : assert(ahead >= 2 && behind >= 1);

  final AudioPlayer _player;

  /// Songs kept loaded after / before the current one.
  final int ahead;
  final int behind;

  final PlaybackRepeat Function() _repeat;
  final PauseRequests _pauses;

  /// Something shown changed (the current song, loading).
  final void Function() _onChanged;

  /// A song couldn't be opened.
  final void Function() _onLoadFailed;

  /// Playback moved to another song by a jump (not by the player itself).
  final void Function() _onCurrentChanged;

  /// The complete logical queue (null: nothing loaded yet).
  PlaybackQueue? queue;

  /// Mirrors just_audio's playlist, item for item.
  List<Slot> _slots = const [];

  /// The song playing (or paused). Authoritative while an operation runs;
  /// otherwise follows the player ([followPlayer]).
  Slot? get current => _current;
  Slot? _current;

  /// Bumped whenever slots are renumbered (new queue, shuffle change, far
  /// jump), so stale slots are never mistaken for current ones.
  int _generation = 0;
  int? _failedGeneration;

  /// The last load failed (and said so): until the next one succeeds, the
  /// player's index and errors mean nothing.
  bool get lastLoadFailed => _failedGeneration == _generation;

  /// While a reload runs, the position it starts from.
  Duration? get loadingFrom => _loadingFrom;
  Duration? _loadingFrom;

  bool get fitsWhole {
    final queue = this.queue;
    return queue != null && queue.length <= behind + ahead + 1;
  }

  /// Whether a play position exists: anywhere while repeating the whole
  /// queue (it wraps), otherwise only inside the queue.
  bool _valid(int position) =>
      _repeat() == PlaybackRepeat.all ||
      (position >= 0 && position < queue!.length);

  bool hasNext(int position) =>
      queue != null &&
      (_repeat() != PlaybackRepeat.off || position < queue!.length - 1);

  bool hasPrevious(int position) =>
      queue != null && (_repeat() != PlaybackRepeat.off || position > 0);

  /// The play position after [position] to skip a broken song to, or null
  /// at the end (with repeat off or one) or when there's nothing else.
  int? nextAfter(int position) {
    final length = queue!.length;
    if (length <= 1) return null;
    if (_repeat() == PlaybackRepeat.all) return position + 1; // wraps
    return position + 1 < length ? position + 1 : null;
  }

  /// The slot at just_audio's playlist [index] (e.g. a song that failed),
  /// or the current one if the index is unknown.
  Slot? slotAt(int? index) =>
      index != null && index >= 0 && index < _slots.length
      ? _slots[index]
      : _current;

  /// The player moved by itself (a song ended): follows it. True if the
  /// current song changed.
  bool followPlayer() {
    if (lastLoadFailed) return false;
    final tag = _player.sequenceState.currentSource?.tag;
    if (tag is! Slot ||
        tag.generation != _generation ||
        identical(tag, _current)) {
      return false;
    }
    _current = tag;
    return true;
  }

  /// Play positions to load around [position].
  List<int> _positionsAround(int position) {
    final queue = this.queue!;
    if (fitsWhole) return List.generate(queue.length, (i) => i);
    return [
      for (var p = position - behind; p <= position + ahead; p++)
        if (_valid(p)) p,
    ];
  }

  Slot _newSlot(int position) =>
      Slot(position, queue!.logicalAt(position), _generation);

  AudioSource _source(Slot slot) =>
      AudioSource.uri(queue!.songs[slot.logical].playbackUri, tag: slot);

  /// Replaces just_audio's playlist with a fresh window around [position]
  /// (new queue, restore, far jump). Returns false (and reports it) if the
  /// song can't be opened.
  Future<bool> reload(int position, {Duration start = Duration.zero}) async {
    if (fitsWhole) position = queue!.wrap(position);
    _generation++;
    final slots = [for (final p in _positionsAround(position)) _newSlot(p)];
    final current = slots.firstWhere((s) => s.position == position);
    _slots = slots;
    _current = current;
    _loadingFrom = start;
    _onChanged();
    try {
      await applyLoopMode();
      await _player.setAudioSources(
        [for (final slot in slots) _source(slot)],
        initialIndex: slots.indexOf(current),
        initialPosition: start,
      );
      return true;
    } catch (_) {
      _failedGeneration = _generation;
      _onLoadFailed();
      return false;
    } finally {
      _loadingFrom = null;
    }
  }

  /// Makes the song at play [position] current: a seek when it's loaded
  /// (the usual case), a reload when it isn't. Then keeps the window full.
  Future<bool> goTo(int position) async {
    final target = _loadedAt(position);
    if (target == null) {
      if (!await reload(position)) return false;
    } else {
      _current = target;
      _onChanged();
      await _player.seek(Duration.zero, index: _slots.indexOf(target));
      if (!await _settleIndex()) {
        // The player didn't move (e.g. it was loading): load it directly.
        if (!await reload(position)) return false;
      }
    }
    _onCurrentChanged();
    await keepFilled();
    return true;
  }

  /// Like [goTo] for a logical index (e.g. a song picked in the queue).
  Future<bool> goToLogical(int logical) async {
    final current = _current;
    if (current != null) {
      final here = _slots.indexOf(current);
      Slot? best;
      for (var i = 0; i < _slots.length; i++) {
        final slot = _slots[i];
        if (slot.logical != logical) continue;
        if (best == null ||
            (i - here).abs() < (_slots.indexOf(best) - here).abs()) {
          best = slot;
        }
      }
      if (best != null) return goTo(best.position);
    }
    return goTo(queue!.positionOf(logical));
  }

  /// The loaded slot for play [position], if any.
  Slot? _loadedAt(int position) {
    final wanted = fitsWhole ? queue!.wrap(position) : position;
    for (final slot in _slots) {
      if (slot.position == wanted) return slot;
    }
    return null;
  }

  /// Keeps songs loaded on each side of the current one. Changes are
  /// batched so they happen every few songs, not on every song:
  /// * fewer than 2 songs left ahead → load up to `2 × ahead` ahead;
  /// * more than `3 × behind` behind → keep only [behind];
  /// * nothing behind (after going back) → load [behind] behind;
  /// * more than `2 × ahead` ahead (after going back) → trim.
  /// At most `3 × behind + 1 + 2 × ahead` songs are loaded.
  Future<void> keepFilled() async {
    final current = _current;
    if (queue == null || fitsWhole || current == null) return;
    if (!_slots.contains(current)) return;
    try {
      // Ahead first: changes after the current song don't move it.
      var here = _slots.indexOf(current);
      final firstInvalidAhead = _slots.indexWhere(
        (s) => !_valid(s.position),
        here + 1,
      );
      if (firstInvalidAhead != -1) {
        await _removeRange(firstInvalidAhead, _slots.length);
      }
      if (_slots.length - here - 1 > 2 * ahead) {
        await _removeRange(here + 1 + ahead, _slots.length);
      }
      if (_slots.length - here - 1 < 2) {
        final from = _slots.last.position + 1;
        final add = [
          for (var p = from; p <= current.position + 2 * ahead; p++)
            if (_valid(p)) _newSlot(p),
        ];
        if (add.isNotEmpty) {
          _slots = [..._slots, ...add];
          await _player.addAudioSources([for (final s in add) _source(s)]);
        }
      }

      // Behind: these shift the current song's index.
      var shifted = false;
      here = _slots.indexOf(current);
      final lastInvalidBehind = _slots.lastIndexWhere(
        (s) => !_valid(s.position),
        here,
      );
      if (lastInvalidBehind != -1) {
        await _removeRange(0, lastInvalidBehind + 1);
        shifted = true;
        here = _slots.indexOf(current);
      }
      if (here > 3 * behind) {
        await _removeRange(0, here - behind);
        shifted = true;
        here = _slots.indexOf(current);
      }
      if (here < 1) {
        final to = _slots.first.position - 1;
        final add = [
          for (var p = current.position - behind; p <= to; p++)
            if (_valid(p)) _newSlot(p),
        ];
        if (add.isNotEmpty) {
          _slots = [...add, ..._slots];
          await _player.insertAudioSources(0, [
            for (final s in add) _source(s),
          ]);
          shifted = true;
        }
      }
      if (shifted) await _settleIndex();
    } catch (_) {
      await _heal();
    }
  }

  /// New neighbours around the current song after the play order changed
  /// (shuffle switched): the current song keeps playing untouched.
  Future<void> reorderAround(int newPosition) async {
    final current = _current!;
    _generation++;
    current
      ..position = newPosition
      ..generation = _generation;
    try {
      var here = _slots.indexOf(current);
      if (here + 1 < _slots.length) {
        await _removeRange(here + 1, _slots.length);
      }
      if (here > 0) await _removeRange(0, here);
      here = 0;
      final positions = _positionsAround(current.position);
      final after = [
        for (final p in positions)
          if (p > current.position) _newSlot(p),
      ];
      final before = [
        for (final p in positions)
          if (p < current.position) _newSlot(p),
      ];
      if (after.isNotEmpty) {
        _slots = [..._slots, ...after];
        await _player.addAudioSources([for (final s in after) _source(s)]);
      }
      if (before.isNotEmpty) {
        _slots = [...before, ..._slots];
        await _player.insertAudioSources(0, [
          for (final s in before) _source(s),
        ]);
      }
      await _settleIndex();
    } catch (_) {
      await _heal();
    }
  }

  /// Leaving "repeat all": shifts the loaded positions back into the queue's
  /// range (positions past an end only existed because the queue wrapped).
  void leaveRepeatAll() {
    final current = _current!;
    final shift = current.position - queue!.wrap(current.position);
    if (shift == 0) return;
    for (final slot in _slots) {
      slot.position -= shift;
    }
  }

  /// just_audio loops only what it holds: one song, or the whole queue when
  /// it's all loaded. Repeating a longer queue is done here, by wrapping.
  Future<void> applyLoopMode() async {
    final mode = switch (_repeat()) {
      PlaybackRepeat.one => LoopMode.one,
      PlaybackRepeat.all when fitsWhole => LoopMode.all,
      _ => LoopMode.off,
    };
    if (_player.loopMode != mode) await _player.setLoopMode(mode);
  }

  Future<void> _removeRange(int start, int end) async {
    _slots = [..._slots]..removeRange(start, end);
    await _player.removeAudioSourceRange(start, end);
  }

  /// Waits until the player reports the current slot's index (after items
  /// before it were added or removed, or a seek). False if it never does.
  Future<bool> _settleIndex() async {
    final expected = _slots.indexOf(_current!);
    if (_player.currentIndex == expected) return true;
    try {
      await _player.currentIndexStream
          .firstWhere((i) => i == expected)
          .timeout(const Duration(seconds: 1));
      return true;
    } on TimeoutException {
      return false;
    }
  }

  /// A playlist change failed: reload the window around the current song
  /// where it was, so the player and the mirror agree again (and keep
  /// playing, unless a pause was asked for meanwhile).
  Future<void> _heal() async {
    final current = _current;
    if (current == null) return;
    final wasPlaying = _player.playing;
    final pauses = _pauses.mark();
    if (await reload(current.position, start: _player.position) &&
        wasPlaying &&
        _pauses.noneSince(pauses)) {
      unawaited(_player.play());
    }
  }
}

/// One loaded item: which song it is ([logical]) and where it sits in the
/// play order ([position], may run past the ends while repeating all).
class Slot {
  Slot(this.position, this.logical, this.generation);

  int position;
  final int logical;
  int generation;

  @override
  String toString() => 'Slot(p$position, #$logical, g$generation)';
}
