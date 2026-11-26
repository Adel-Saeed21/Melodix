/// Remembers pause requests, so that playback started after a load (which
/// takes time) never overrides a pause asked for meanwhile: a headset
/// button, the notification, or headphones being unplugged.
///
/// Take a [mark] before the load; once it's done, play only if
/// [noneSince] that mark.
class PauseRequests {
  int _count = 0;

  /// A pause was asked for.
  void record() => _count++;

  /// Where things stand now (before starting a load).
  int mark() => _count;

  /// No pause was asked for since [mark].
  bool noneSince(int mark) => _count == mark;
}
