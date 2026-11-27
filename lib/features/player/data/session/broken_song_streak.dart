/// Broken songs skipped in a row (e.g. their files were deleted): playback
/// goes on with the next song, like other players, but a queue of broken
/// files stops instead of skipping forever.
class BrokenSongStreak {
  /// Broken songs skipped in a row before playback stops.
  static const int maxSkips = 3;

  /// A song that plays this far really plays: the streak is over.
  static const Duration _reallyPlaying = Duration(seconds: 2);

  int _count = 0;

  /// Playback reached [position] in the current song.
  void reached(Duration position) {
    if (_count > 0 && position > _reallyPlaying) _count = 0;
  }

  /// A song failed: true to skip to the next one, false to stop (at the
  /// end of the queue, or after [maxSkips] broken songs in a row).
  bool skipAnother({required bool hasNext}) {
    if (!hasNext || _count >= maxSkips) {
      _count = 0;
      return false;
    }
    _count++;
    return true;
  }
}
