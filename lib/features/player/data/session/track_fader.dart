import 'dart:math';

/// Smooth song changes on the app's single player: the last [length] of a
/// song fades out and, right after a fade-out, the next song (or the same
/// one, repeating) fades in over [length]. just_audio plays one song at a
/// time, so the songs never overlap: a fade, not a crossfade. Gapless
/// albums are untouched while it's off.
///
/// The fade multiplies the app's own volume ([setVolume], e.g. the sleep
/// timer's fade-out), so the two never fight. The phone's volume is never
/// touched.
///
/// A low volume never sticks: any position outside the fades (a seek, a
/// song picked in the middle of a fade) brings it straight back to full.
class TrackFader {
  TrackFader(this._setPlayerVolume);

  final Future<void> Function(double volume) _setPlayerVolume;

  /// A fade takes at most this share of a song, so short songs aren't all
  /// fade (1/4 of the song).
  static const int _maxShareDivisor = 4;

  /// Volume steps smaller than this aren't sent to the player (positions
  /// arrive several times a second).
  static const double _step = 0.01;

  Duration get length => _length;
  Duration _length = Duration.zero;

  double _volume = 1;
  double _gain = 1;
  double? _applied;

  /// The last position was in a song's fade-out.
  bool _fadingOut = false;

  /// A song started right after a fade-out: fading in.
  bool _fadingIn = false;

  /// How long each fade lasts (zero: off).
  Future<void> setLength(Duration length) {
    _length = length.isNegative ? Duration.zero : length;
    if (_length == Duration.zero) {
      _fadingOut = false;
      _fadingIn = false;
      _gain = 1;
    }
    return _push();
  }

  /// The app's own volume (0–1), before the fade.
  Future<void> setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    return _push();
  }

  /// Where playback is in the current song ([duration] null or zero while
  /// it's unknown).
  Future<void> update({required Duration position, Duration? duration}) {
    if (_length == Duration.zero) return Future.value();
    final total = duration ?? Duration.zero;
    final fade = total > Duration.zero
        ? Duration(
            microseconds: min(
              _length.inMicroseconds,
              total.inMicroseconds ~/ _maxShareDivisor,
            ),
          )
        : _length;
    final f = fade.inMilliseconds;
    if (f <= 0) {
      _fadingOut = _fadingIn = false;
      _gain = 1;
      return _push();
    }
    final p = position.inMilliseconds;
    // A start after a fade-out (the next song, or this one repeating).
    if (_fadingOut && p < f) _fadingIn = true;
    // `p >= f`: right after a song change the player may still report the
    // previous song's length; the start of a song is never its end.
    final left = total > Duration.zero
        ? (total - position).inMilliseconds
        : null;
    final inFadeOut = left != null && left < f && p >= f;

    var gain = 1.0;
    if (inFadeOut) gain = max(0, left) / f;
    if (_fadingIn) {
      if (p >= f || p < 0) {
        _fadingIn = false;
      } else {
        gain = min(gain, p / f);
      }
    }
    _fadingOut = inFadeOut;
    _gain = gain.clamp(0.0, 1.0);
    return _push();
  }

  Future<void> _push() {
    final volume = _volume * _gain;
    final last = _applied;
    final edge = volume == 0 || volume == _volume;
    if (last != null && (last - volume).abs() < _step && !edge) {
      return Future.value();
    }
    if (last == volume) return Future.value();
    _applied = volume;
    return _setPlayerVolume(volume);
  }
}
