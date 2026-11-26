import 'dart:async';

import 'package:audio_session/audio_session.dart';

/// Sets the app's audio session up for music (audio focus, ducking for
/// other apps' sounds) the first time something plays, and reports when
/// headphones are unplugged.
class AudioFocus {
  AudioFocus({Future<AudioSession> Function()? session})
    : _session = session ?? (() => AudioSession.instance);

  final Future<AudioSession> Function() _session;
  bool _activated = false;
  StreamSubscription<void>? _noisy;

  /// Once only. [onBecomingNoisy] runs when headphones are unplugged.
  ///
  /// just_audio pauses the player for that too, but directly; routing it
  /// through the repository's pause also records it, so a song still
  /// loading won't start on the speaker once it's ready.
  Future<void> activate({required void Function() onBecomingNoisy}) async {
    if (_activated) return;
    _activated = true;
    final session = await _session();
    await session.configure(const AudioSessionConfiguration.music());
    _noisy = session.becomingNoisyEventStream.listen((_) => onBecomingNoisy());
  }

  Future<void> dispose() async => _noisy?.cancel();
}
