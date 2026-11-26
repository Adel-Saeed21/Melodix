import 'dart:async';

import 'package:melodix/features/player/domain/entities/equalizer_preset.dart';
import 'package:melodix/features/player/domain/repositories/equalizer_engine.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';
import 'package:melodix/features/player/presentation/logic/audio_settings_cubit.dart';

/// Keeps the music player sounding as [AudioSettings] say: applied at
/// start, then each change as it's made (only what changed).
class AudioSettingsBinder {
  AudioSettingsBinder({
    required Stream<AudioSettings> settings,
    required AudioSettings initial,
    required this._player,
    required this._equalizer,
  }) {
    _apply(null, initial);
    var last = initial;
    _subscription = settings.listen((next) {
      _apply(last, next);
      last = next;
    });
  }

  final PlayerRepository _player;
  final EqualizerEngine _equalizer;
  late final StreamSubscription<AudioSettings> _subscription;

  void _apply(AudioSettings? before, AudioSettings now) {
    if (before?.speed != now.speed) unawaited(_player.setSpeed(now.speed));
    if (before?.skipSilence != now.skipSilence) {
      unawaited(_player.setSkipSilence(now.skipSilence));
    }
    if (!_equalizer.isSupported) return;
    if (before == null || before.gains != now.gains) {
      final gains = now.gains;
      unawaited(_equalizer.setGains((hz) => gainAt(hz, gains)));
    }
    if (before?.equalizerOn != now.equalizerOn) {
      unawaited(_equalizer.setEnabled(now.equalizerOn));
    }
  }

  Future<void> dispose() => _subscription.cancel();
}
