import 'dart:math' as math;

/// The five bands the equalizer screen shows (Hz). A phone's equalizer may
/// have other bands: [gainAt] fits any frequency between them.
const List<double> equalizerBandsHz = [60, 230, 910, 3600, 14000];

/// Most a band is raised or lowered on screen (dB).
const double equalizerMaxGainDb = 12;

/// Sound shapes to pick from; [custom] is the user's own bars.
enum EqualizerPreset {
  flat('Flat', [0, 0, 0, 0, 0]),
  bassBoost('Bass boost', [6, 4, 0, 0, 0]),
  vocal('Vocal', [-2, -1, 3, 4, 1]),
  rock('Rock', [5, 2, -2, 2, 5]),
  pop('Pop', [-1, 2, 4, 2, -1]),
  jazz('Jazz', [3, 1, -1, 2, 4]),
  classical('Classical', [4, 2, -1, 2, 3]),
  electronic('Electronic', [5, 3, 0, 2, 4]),
  trebleBoost('Treble boost', [0, 0, 0, 3, 6]),
  custom('Custom', [0, 0, 0, 0, 0]);

  const EqualizerPreset(this.label, this.gains);

  final String label;

  /// dB per band of [equalizerBandsHz] (for [custom], the user's own).
  final List<double> gains;
}

/// The gain at [hz] for [gains] over [equalizerBandsHz]: straight lines
/// between bands on a log-frequency scale; flat beyond the ends.
double gainAt(double hz, List<double> gains) {
  assert(gains.length == equalizerBandsHz.length);
  if (hz <= equalizerBandsHz.first) return gains.first;
  if (hz >= equalizerBandsHz.last) return gains.last;
  for (var i = 0; i < equalizerBandsHz.length - 1; i++) {
    final lo = equalizerBandsHz[i];
    final hi = equalizerBandsHz[i + 1];
    if (hz <= hi) {
      final t = (math.log(hz) - math.log(lo)) / (math.log(hi) - math.log(lo));
      return gains[i] + (gains[i + 1] - gains[i]) * t;
    }
  }
  return gains.last;
}
