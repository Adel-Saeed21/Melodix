import 'dart:async';

import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_song_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_song_favorite_usecase.dart';

/// The playing song's ♥, kept live from storage (a change made anywhere in
/// the app shows), and flipped from the notification's button.
class CurrentSongFavorite {
  CurrentSongFavorite({
    required this._watch,
    required this._toggle,
    required this._onChanged,
  });

  final WatchSongFavoriteUseCase _watch;
  final ToggleSongFavoriteUseCase _toggle;

  /// The flag changed (the notification's button should follow).
  final void Function() _onChanged;

  bool _favorite = false;
  int? _songId;
  StreamSubscription<bool>? _subscription;

  bool get isFavorite => _favorite;

  /// Follows [song]'s flag (none when [song] is null).
  void follow(Song? song) {
    if (song?.id == _songId) return;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _songId = song?.id;
    // The queue's copy until storage answers (right away, normally).
    _favorite = song?.isFavorite ?? false;
    if (song == null) return;
    _subscription = _watch(song.id).listen((on) => _set(song.id, on));
  }

  /// Flips the flag. The button changes at once; storage then confirms it
  /// (or a failure puts it back).
  Future<void> toggle() async {
    final songId = _songId;
    if (songId == null) return;
    final before = _favorite;
    _set(songId, !before);
    final result = await _toggle(songId);
    result.fold((_) => _set(songId, before), (on) => _set(songId, on));
  }

  void _set(int songId, bool favorite) {
    // Answers about a song that's no longer playing are ignored.
    if (songId != _songId || favorite == _favorite) return;
    _favorite = favorite;
    _onChanged();
  }

  Future<void> dispose() async => _subscription?.cancel();
}
