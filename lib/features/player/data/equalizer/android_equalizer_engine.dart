import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:melodix/features/player/domain/repositories/equalizer_engine.dart';

/// Android's equalizer on the music player's audio session, through the
/// app's own `melodix/equalizer` channel (`NativeEqualizer.kt`).
///
/// It's deliberately *not* just_audio's `AndroidEqualizer`: that one is
/// switched on inside every song load, so a phone whose equalizer fails
/// (seen on a Realme, Android 11) couldn't play any song. Here the
/// equalizer follows the player's audio session from the side: if it
/// fails, it's logged and the music plays as recorded.
///
/// The chosen settings are remembered and applied each time the player
/// gets a (new) audio session, so they're never lost to timing.
class AndroidEqualizerEngine implements EqualizerEngine {
  AndroidEqualizerEngine({
    required Stream<int?> audioSessionIds,
    @visibleForTesting this._channel = const MethodChannel('melodix/equalizer'),
  }) {
    _sessions = audioSessionIds
        .where((id) => id != null && id > 0)
        .cast<int>()
        .distinct()
        .listen((id) => _run(() => _attach(id)));
  }

  final MethodChannel _channel;
  late final StreamSubscription<int> _sessions;

  bool _enabled = false;
  double Function(double hz)? _gains;

  /// The attached equalizer's bands; null until attached (or if it failed).
  _Bands? _bands;

  /// Calls run one after another, in the order they were made.
  Future<void> _queue = Future.value();

  @override
  bool get isSupported => true;

  @override
  Future<void> setEnabled(bool enabled) {
    _enabled = enabled;
    return _run(_pushEnabled);
  }

  @override
  Future<void> setGains(double Function(double hz) gainAtHz) {
    _gains = gainAtHz;
    return _run(_pushGains);
  }

  Future<void> dispose() async {
    await _sessions.cancel();
    await _run(() => _call('release'));
  }

  Future<void> _attach(int sessionId) async {
    _bands = null;
    final answer = await _call('attach', {'sessionId': sessionId});
    if (answer is! Map) return;
    _bands = _Bands(
      centers: [
        for (final c in answer['centers'] as List) (c as num).toDouble(),
      ],
      minDb: (answer['minDb'] as num).toDouble(),
      maxDb: (answer['maxDb'] as num).toDouble(),
    );
    // What the user chose, on the new equalizer: shape first, then on/off.
    await _pushGains();
    await _pushEnabled();
  }

  Future<void> _pushEnabled() async {
    if (_bands == null) return; // applied once attached
    await _call('setEnabled', {'enabled': _enabled});
  }

  Future<void> _pushGains() async {
    final bands = _bands;
    final gains = _gains;
    if (bands == null || gains == null) return;
    await _call('setGains', {
      'gains': [
        for (final hz in bands.centers)
          gains(hz).clamp(bands.minDb, bands.maxDb).toDouble(),
      ],
    });
  }

  /// A step that fails (e.g. an odd answer) is logged; the next ones
  /// still run.
  Future<void> _run(Future<void> Function() step) =>
      _queue = _queue.then((_) => step()).catchError((Object error) {
        debugPrint('melodix.equalizer: $error');
      });

  /// Never throws: a failing equalizer must not affect anything else.
  Future<Object?> _call(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<Object?>(method, arguments);
    } catch (error) {
      debugPrint('melodix.equalizer: $method failed: $error');
      return null;
    }
  }
}

class _Bands {
  const _Bands({
    required this.centers,
    required this.minDb,
    required this.maxDb,
  });

  /// Each band's centre frequency (Hz), in band order.
  final List<double> centers;
  final double minDb;
  final double maxDb;
}
