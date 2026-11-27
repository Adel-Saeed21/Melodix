/// Where the player reports what was listened to ("Most played", recents,
/// listening stats).
abstract interface class PlayRecorder {
  /// One play of the song (once per listen past the threshold, see
  /// `ListeningTracker`).
  Future<void> recordPlay(int songId);

  /// [listened] more of the song was really heard.
  Future<void> addListening(int songId, Duration listened);
}
