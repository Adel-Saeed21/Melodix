import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/song_playback.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/player/presentation/widgets/mini_player_bar.dart';

/// The player as the music library sees it (see [SongPlayback]).
class PlayerSongPlayback implements SongPlayback {
  const PlayerSongPlayback(this._player);

  final PlayerCubit _player;

  @override
  Future<void> playSongs(List<Song> songs, int index, {String? title}) =>
      _player.playSongs(songs, index, title: title);

  @override
  Future<void> shufflePlay(List<Song> songs, {String? title}) =>
      _player.shufflePlay(songs, title: title);

  @override
  Future<void> playNext(List<Song> songs) => _player.playNext(songs);

  @override
  Future<void> addToQueue(List<Song> songs) => _player.addToQueue(songs);

  @override
  CurrentSong get current => (
    songId: _player.state.currentSong?.id,
    isPlaying: _player.state.isPlaying,
  );

  @override
  Stream<CurrentSong> get changes => _player.stream
      .map(
        (state) => (songId: state.currentSong?.id, isPlaying: state.isPlaying),
      )
      .distinct();

  @override
  Widget miniPlayer() => const MiniPlayerBar();
}
