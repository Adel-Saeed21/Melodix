import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:melodix/features/player/domain/repositories/equalizer_engine.dart';

/// Android's equalizer, attached to the music player's audio pipeline.
///
/// Its bands are known only once the player has opened its audio session
/// (the first song): gains set before that are applied then.
class AndroidEqualizerEngine implements EqualizerEngine {
  AndroidEqualizerEngine(this._equalizer);

  final AndroidEqualizer _equalizer;
  double Function(double hz)? _pending;
  bool _waiting = false;

  @override
  bool get isSupported => true;

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await _equalizer.setEnabled(enabled);
    } catch (_) {
      // The player isn't ready yet; just_audio applies it when it is.
    }
  }

  @override
  Future<void> setGains(double Function(double hz) gainAtHz) async {
    _pending = gainAtHz;
    if (_waiting) return; // the latest is applied when ready
    _waiting = true;
    try {
      final parameters = await _equalizer.parameters;
      // Until the newest gains are on (a slider moved meanwhile).
      double Function(double hz)? applied;
      while (!identical(applied, _pending)) {
        final gains = applied = _pending!;
        for (final band in parameters.bands) {
          final db = gains(band.centerFrequency)
              .clamp(parameters.minDecibels, parameters.maxDecibels);
          await band.setGain(db);
        }
      }
    } catch (_) {
      // No equalizer on this phone after all: the music plays as it is.
    } finally {
      _waiting = false;
    }
  }
}
