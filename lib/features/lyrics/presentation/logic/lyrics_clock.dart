/// What synced lyrics need from whatever is playing the song: where it is
/// now, each change of that, and a way to jump to a line.
///
/// Lyrics owns this interface and the player implements it (see
/// `PlayerLyricsClock`), so the lyrics feature doesn't depend on the
/// player. Provided above `LyricsView` (a `RepositoryProvider`).
abstract interface class LyricsClock {
  /// The playback position now.
  Duration get position;

  /// The position, each time it changes.
  Stream<Duration> get positions;

  /// Jumps playback to [position] (a tapped line).
  Future<void> seek(Duration position);
}
