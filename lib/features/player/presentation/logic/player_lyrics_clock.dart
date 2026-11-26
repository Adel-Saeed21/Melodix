import 'package:melodix/features/lyrics/presentation/logic/lyrics_clock.dart';
import 'package:melodix/features/player/presentation/logic/playback_progress_cubit.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';

/// The player as the lyrics see it: the song's position and seeking.
class PlayerLyricsClock implements LyricsClock {
  const PlayerLyricsClock({required this._progress, required this._player});

  final PlaybackProgressCubit _progress;
  final PlayerCubit _player;

  @override
  Duration get position => _progress.state.position;

  @override
  Stream<Duration> get positions => _progress.stream.map((p) => p.position);

  @override
  Future<void> seek(Duration position) => _player.seek(position);
}
