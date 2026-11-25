import 'dart:math';

import 'package:melodix/features/music_library/domain/entities/song.dart';

/// The complete logical queue and the order it plays in.
///
/// Two kinds of index:
/// * **logical index**: a song's position in [songs] (the order the user
///   sees in the queue sheet; what `NowPlaying.currentIndex` reports);
/// * **play position**: a step in the play order. Without shuffle it equals
///   the logical index; with shuffle it's the step in a stable shuffled
///   order that only changes when shuffle is switched on or a new queue
///   starts.
///
/// Play positions may run past either end ("unwrapped") when the queue
/// repeats; [logicalAt] wraps them.
class PlaybackQueue {
  /// [songs] is kept as given (not copied): pass a list that won't change,
  /// so the queue's identity stays stable for the UI.
  PlaybackQueue(
    this.songs, {
    required int startIndex,
    required bool shuffled,
    required Random random,
  }) : _order = List.generate(songs.length, (i) => i),
       _positionOf = List.generate(songs.length, (i) => i),
       _shuffled = false {
    if (shuffled) shuffle(firstLogical: startIndex, random: random);
  }

  /// A queue with a given play [order] (used by [withAdded]).
  PlaybackQueue._ordered(this.songs, List<int> order, {required this._shuffled})
    : _order = List.of(order),
      _positionOf = List.filled(order.length, 0) {
    for (var p = 0; p < order.length; p++) {
      _positionOf[order[p]] = p;
    }
  }

  final List<Song> songs;
  final List<int> _order;
  final List<int> _positionOf;
  bool _shuffled;

  int get length => songs.length;
  bool get isShuffled => _shuffled;

  /// The logical index played at [position] (wrapped into range).
  int logicalAt(int position) => _order[wrap(position)];

  /// The play position of the song at [logical].
  int positionOf(int logical) => _positionOf[logical];

  /// [position] wrapped into `0 .. length - 1`.
  int wrap(int position) {
    final n = length;
    return ((position % n) + n) % n;
  }

  /// A new random play order that starts with [firstLogical] (like the
  /// player's own shuffle: the current song first, the rest random).
  void shuffle({required int firstLogical, required Random random}) {
    final rest = [
      for (var i = 0; i < length; i++)
        if (i != firstLogical) i,
    ]..shuffle(random);
    _setOrder([firstLogical, ...rest]);
    _shuffled = true;
  }

  /// A copy with [added] songs in it:
  /// * [next]: right after the song at [currentLogical], in the list and in
  ///   the play order, so they play next (shuffled or not);
  /// * otherwise at the end of both.
  ///
  /// The rest keeps its order, and the song at [currentLogical] keeps its
  /// index (nothing is inserted before it).
  PlaybackQueue withAdded(
    List<Song> added, {
    required int currentLogical,
    required bool next,
  }) {
    final count = added.length;
    final at = next ? currentLogical + 1 : length;
    int moved(int logical) => logical < at ? logical : logical + count;
    final inserted = [for (var i = 0; i < count; i++) at + i];
    final order = <int>[];
    for (final logical in _order) {
      order.add(moved(logical));
      if (next && logical == currentLogical) order.addAll(inserted);
    }
    if (!next) order.addAll(inserted);
    return PlaybackQueue._ordered(
      List.unmodifiable([
        ...songs.sublist(0, at),
        ...added,
        ...songs.sublist(at),
      ]),
      order,
      shuffled: _shuffled,
    );
  }

  /// Back to the queue's own order.
  void unshuffle() {
    _setOrder(List.generate(length, (i) => i));
    _shuffled = false;
  }

  void _setOrder(List<int> order) {
    for (var p = 0; p < order.length; p++) {
      _order[p] = order[p];
      _positionOf[order[p]] = p;
    }
  }
}
