/// The phone's sound equalizer for the music player.
abstract interface class EqualizerEngine {
  /// False where the phone offers none (e.g. iOS): the screen says so.
  bool get isSupported;

  /// On (shaped by [setGains]) or off (the music as recorded).
  Future<void> setEnabled(bool enabled);

  /// [gainAtHz] gives the dB for a frequency; each of the phone's own
  /// bands takes the value at its centre, within the phone's limits.
  Future<void> setGains(double Function(double hz) gainAtHz);
}

/// No equalizer on this platform.
class UnsupportedEqualizerEngine implements EqualizerEngine {
  const UnsupportedEqualizerEngine();

  @override
  bool get isSupported => false;

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<void> setGains(double Function(double hz) gainAtHz) async {}
}
