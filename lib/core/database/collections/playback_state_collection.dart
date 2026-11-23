import 'package:isar_community/isar.dart';

part 'playback_state_collection.g.dart';

enum PlayerRepeatMode { off, all, one }

/// Where the current queue was started from, e.g. to show "Playing from
/// [playlist name]" after a restore.
enum PlaybackSource { allSongs, playlist, favorites, recent, search }

/// The player's last state, so playback can resume where the user left off
/// after the app is closed or killed.
///
/// There is only ever one row ([singletonId]).
@collection
class PlaybackStateCollection {
  static const int singletonId = 0;

  Id id = singletonId;

  /// Song ids in the order they will play (already shuffled if [shuffle]).
  List<int> queueSongIds = [];

  /// The queue before shuffling, so turning shuffle off restores the order.
  List<int> originalQueueSongIds = [];

  /// Index of the current song in [queueSongIds].
  int currentIndex = 0;

  /// Position in the current song.
  int positionMs = 0;

  bool shuffle = false;

  @enumerated
  PlayerRepeatMode repeatMode = PlayerRepeatMode.off;

  double speed = 1.0;

  @enumerated
  PlaybackSource source = PlaybackSource.allSongs;

  /// E.g. the playlist id when [source] is [PlaybackSource.playlist].
  int? sourceId;

  late DateTime updatedAt;

  PlaybackStateCollection();

  @ignore
  Duration get position => Duration(milliseconds: positionMs);

  @ignore
  int? get currentSongId =>
      (currentIndex >= 0 && currentIndex < queueSongIds.length)
      ? queueSongIds[currentIndex]
      : null;
}
