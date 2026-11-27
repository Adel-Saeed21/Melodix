import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

/// The song playing now ([songId] null: none) and whether it's playing.
typedef CurrentSong = ({int? songId, bool isPlaying});

/// What the music library needs from whatever plays its songs: start a
/// list, queue songs, know what's playing, and show the player's bar.
///
/// The library owns this interface and the player implements it
/// (`PlayerSongPlayback`), so the library doesn't depend on the player
/// (the player depends on the library: it plays the library's songs).
/// Provided at the app's root.
abstract interface class SongPlayback {
  Future<void> playSongs(List<Song> songs, int index, {String? title});

  Future<void> shufflePlay(List<Song> songs, {String? title});

  Future<void> playNext(List<Song> songs);

  Future<void> addToQueue(List<Song> songs);

  CurrentSong get current;

  /// [current], each time it changes.
  Stream<CurrentSong> get changes;

  /// The player's bar, for the bottom of a page (album, artist, playlist).
  Widget miniPlayer();

  /// The one above [context]; null where there's none (a widget shown on
  /// its own, e.g. in a test).
  static SongPlayback? maybeOf(BuildContext context) {
    try {
      return context.read<SongPlayback>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
