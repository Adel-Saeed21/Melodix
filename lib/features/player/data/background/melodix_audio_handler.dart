import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/service/local_song_builder.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_song_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_song_favorite_usecase.dart';
import 'package:melodix/features/player/data/background/now_playing_artwork_files.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/entities/playback_progress.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';

/// Connects the system's media session to the app's [PlayerRepository].
///
/// The media session is what keeps music playing with the app in the
/// background (as a foreground service on Android) and what the system
/// shows as the media notification and lock-screen controls. Headset,
/// Bluetooth and car buttons arrive here too.
///
/// * **Commands** from the system (play, pause, next, previous, seek, ♥,
///   shuffle, ...) go straight to the same [PlayerRepository] (and
///   favourite use case) the app's UI uses, so both always agree.
/// * **State** flows back: every [NowPlaying] becomes the session's
///   [playbackState] and [mediaItem]. Position ticks are not forwarded: the
///   system extrapolates the position from the last update while playing,
///   so only real jumps (seeks) are sent. That keeps platform-channel
///   traffic to a few messages per song.
/// * The queue is not published: it can hold 10,000 songs and nothing on
///   the notification or lock screen shows it.
///
/// **Buttons.** Previous, play/pause and next use the app's rounded icons
/// (Android 12 and below; Android 13+ draws these three itself). ♥ and
/// shuffle are custom session actions: Android 13+ shows them in the two
/// extra slots of its media player (notification, lock screen, Quick
/// Settings), and they follow changes made anywhere in the app.
class MelodixAudioHandler extends BaseAudioHandler {
  MelodixAudioHandler(
    this._player, {
    required this._artwork,
    required this._watchFavorite,
    required this._toggleFavorite,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _subscription = _player.watch().listen(_onNowPlaying);
    _progressSubscription = _player.watchProgress().listen(_onProgress);
  }

  final PlayerRepository _player;
  final NowPlayingArtworkFiles _artwork;
  final WatchSongFavoriteUseCase _watchFavorite;
  final ToggleSongFavoriteUseCase _toggleFavorite;
  final DateTime Function() _clock;
  late final StreamSubscription<NowPlaying> _subscription;
  late final StreamSubscription<PlaybackProgress> _progressSubscription;

  /// Where playback is in the song (from the progress stream).
  Duration _position = Duration.zero;

  /// The last state sent to the system, to skip sending repeats.
  _Sent? _sent;

  /// After [stop]: report idle (no notification) until playback resumes.
  bool _stopped = false;

  /// The current song's favourite flag, kept live from storage.
  bool _favorite = false;
  int? _favoriteSongId;
  StreamSubscription<bool>? _favoriteSubscription;

  /// A position further than this from where the system expects it counts
  /// as a jump (a seek) and is sent.
  static const Duration _driftTolerance = Duration(milliseconds: 1500);

  /// Custom action names (sent back by the system when tapped).
  static const String favoriteAction = 'melodix.favorite';
  static const String shuffleAction = 'melodix.shuffle';

  // Commands from the system

  @override
  Future<void> play() {
    _stopped = false;
    return _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.next();

  @override
  Future<void> skipToPrevious() => _player.previous();

  @override
  Future<void> skipToQueueItem(int index) {
    _stopped = false;
    return _player.skipToIndex(index);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) =>
      _player.setRepeatMode(switch (repeatMode) {
        AudioServiceRepeatMode.none => PlaybackRepeat.off,
        AudioServiceRepeatMode.one => PlaybackRepeat.one,
        AudioServiceRepeatMode.all ||
        AudioServiceRepeatMode.group => PlaybackRepeat.all,
      });

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) =>
      _player.setShuffle(shuffleMode != AudioServiceShuffleMode.none);

  /// The ♥ and shuffle buttons.
  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    switch (name) {
      case favoriteAction:
        await _toggleCurrentFavorite();
      case shuffleAction:
        await _player.setShuffle(!_player.current.shuffle);
    }
  }

  /// Pauses and removes the notification (e.g. it was swiped away while
  /// paused). The song and position stay, ready to resume in the app.
  @override
  Future<void> stop() async {
    await _player.pause();
    _stopped = true;
    _send(_player.current, force: true);
  }

  /// The app was swiped away from recent apps: stop, even while playing.
  /// Playback pauses (the song and position are saved), the notification
  /// and lock-screen controls go away and the background service ends, so
  /// nothing keeps running. Reopening the app shows the song, paused,
  /// ready to resume.
  @override
  Future<void> onTaskRemoved() => stop();

  /// Stops listening (tests; the app keeps one handler for its life).
  Future<void> dispose() async {
    await _favoriteSubscription?.cancel();
    await _progressSubscription.cancel();
    await _subscription.cancel();
  }

  /// Flips the current song's favourite. The button changes at once; the
  /// live favourite flag then confirms it (or a failure puts it back).
  Future<void> _toggleCurrentFavorite() async {
    final songId = _favoriteSongId;
    if (songId == null) return;
    final before = _favorite;
    _setFavorite(songId, !before);
    final result = await _toggleFavorite(songId);
    result.fold(
      (_) => _setFavorite(songId, before),
      (isFavorite) => _setFavorite(songId, isFavorite),
    );
  }

  void _setFavorite(int songId, bool favorite) {
    // Ignore answers about a song that's no longer playing.
    if (songId != _favoriteSongId || favorite == _favorite) return;
    _favorite = favorite;
    _send(_player.current);
  }

  /// Follows [song]'s favourite flag (none when [song] is null).
  void _followFavorite(Song? song) {
    if (song?.id == _favoriteSongId) return;
    unawaited(_favoriteSubscription?.cancel());
    _favoriteSubscription = null;
    _favoriteSongId = song?.id;
    // The queue's copy until storage answers (right away, normally).
    _favorite = song?.isFavorite ?? false;
    if (song == null) return;
    _favoriteSubscription = _watchFavorite(song.id)
        .listen((favorite) => _setFavorite(song.id, favorite));
  }

  // State to the system

  /// Position ticks: only a jump (a seek) is sent; the system moves the
  /// position on by itself while playing.
  void _onProgress(PlaybackProgress progress) {
    _position = progress.position;
    _send(_player.current);
  }

  void _onNowPlaying(NowPlaying state) {
    if (state.isPlaying) _stopped = false;
    _send(state);
  }

  void _send(NowPlaying state, {bool force = false}) {
    final song = _stopped ? null : state.currentSong;
    _followFavorite(song);
    _sendMediaItem(song, state.duration);

    final now = _clock();
    final next = _Sent.of(
      state,
      stopped: _stopped || song == null,
      favorite: _favorite,
    );
    final previous = _sent;
    if (!force &&
        previous != null &&
        previous.sameApartFromPosition(next) &&
        !_jumped(previous, _position, now)) {
      return;
    }
    _sent = next.at(_position, now);
    playbackState.add(_playbackState(state, next, now));
  }

  /// Whether [position] is far from where the system thinks playback is:
  /// moving on from the last update while playing, standing still if not.
  bool _jumped(_Sent sent, Duration position, DateTime now) {
    final expected = sent.playing
        ? sent.position + now.difference(sent.time)
        : sent.position;
    return (position - expected).abs() > _driftTolerance;
  }

  PlaybackState _playbackState(NowPlaying state, _Sent sent, DateTime now) {
    final hasSong = !sent.stopped;
    return PlaybackState(
      // Android 13+ puts the custom ♥ in the slot left of "previous" and
      // shuffle right of "next". Earlier versions show the other three.
      controls: [
        if (hasSong) _favoriteControl(sent.favorite),
        _previous,
        if (sent.playing) _pause else _play,
        _next,
        if (hasSong) _shuffleControl(sent.shuffle),
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.skipToQueueItem,
        MediaAction.setRepeatMode,
        MediaAction.setShuffleMode,
      },
      // Previous, play/pause, next in the collapsed notification (Android
      // 12 and below). These count only the standard buttons: the custom
      // ♥ and shuffle aren't notification buttons there.
      androidCompactActionIndices: const [0, 1, 2],
      processingState: sent.processing,
      playing: sent.playing,
      updatePosition: _position,
      updateTime: now,
      queueIndex: sent.stopped ? null : state.currentIndex,
      repeatMode: switch (state.repeatMode) {
        PlaybackRepeat.off => AudioServiceRepeatMode.none,
        PlaybackRepeat.one => AudioServiceRepeatMode.one,
        PlaybackRepeat.all => AudioServiceRepeatMode.all,
      },
      shuffleMode: state.shuffle
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    );
  }

  /// Sends the song's details when the song (or its real duration)
  /// changes, then its cover once the cover file is ready.
  void _sendMediaItem(Song? song, Duration playerDuration) {
    final current = mediaItem.value;
    if (song == null) {
      if (current != null) mediaItem.add(null);
      return;
    }
    final id = '${song.id}';
    final duration = playerDuration > Duration.zero
        ? playerDuration
        : song.duration;
    if (current?.id == id && current?.duration == duration) return;

    final sameSong = current?.id == id;
    mediaItem.add(
      mediaItemFor(
        song,
        duration: duration,
        // Keep the cover while only the duration is corrected.
        artUri: sameSong ? current?.artUri : null,
      ),
    );
    if (sameSong) return;
    unawaited(
      _artwork.uriFor(song).then((uri) {
        final latest = mediaItem.value;
        // Only if this song is still the one showing.
        if (uri != null && latest != null && latest.id == id) {
          mediaItem.add(latest.copyWith(artUri: uri));
        }
      }),
    );
  }

  /// What the system shows for [song]: its title, then "Artist · Album".
  /// Missing tags (saved as "Unknown artist" / "Unknown album") are left
  /// out of the subtitle and not reported as real artist or album names.
  static MediaItem mediaItemFor(
    Song song, {
    required Duration duration,
    Uri? artUri,
  }) {
    final title = song.title.trim().isEmpty
        ? AppStrings.unknownSong
        : song.title;
    final artist = _known(song.artist, unknownArtist);
    final album = _known(song.album, unknownAlbum);
    final subtitle = [?artist, ?album].join(' · ');
    return MediaItem(
      id: '${song.id}',
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      artUri: artUri,
      // The notification and lock screen's two lines.
      displayTitle: title,
      displaySubtitle: subtitle.isEmpty ? unknownArtist : subtitle,
    );
  }

  static String? _known(String value, String unknown) {
    final trimmed = value.trim();
    return trimmed.isEmpty || trimmed == unknown ? null : trimmed;
  }

  // Buttons (icons in android/app/src/main/res/drawable)

  static const _previous = MediaControl(
    androidIcon: 'drawable/ic_media_previous',
    label: AppStrings.previous,
    action: MediaAction.skipToPrevious,
  );
  static const _play = MediaControl(
    androidIcon: 'drawable/ic_media_play',
    label: AppStrings.play,
    action: MediaAction.play,
  );
  static const _pause = MediaControl(
    androidIcon: 'drawable/ic_media_pause',
    label: AppStrings.pause,
    action: MediaAction.pause,
  );
  static const _next = MediaControl(
    androidIcon: 'drawable/ic_media_next',
    label: AppStrings.next,
    action: MediaAction.skipToNext,
  );

  static MediaControl _favoriteControl(bool favorite) => MediaControl.custom(
    androidIcon: favorite
        ? 'drawable/ic_media_favorite'
        : 'drawable/ic_media_favorite_border',
    label: favorite
        ? AppStrings.removeFromFavourites
        : AppStrings.addToFavourites,
    name: favoriteAction,
  );

  static MediaControl _shuffleControl(bool shuffle) => MediaControl.custom(
    androidIcon: shuffle
        ? 'drawable/ic_media_shuffle_on'
        : 'drawable/ic_media_shuffle',
    label: shuffle ? AppStrings.turnShuffleOff : AppStrings.turnShuffleOn,
    name: shuffleAction,
  );
}

/// What was last sent to the system (minus the position's natural drift).
class _Sent {
  const _Sent({
    required this.playing,
    required this.processing,
    required this.stopped,
    required this.index,
    required this.repeat,
    required this.shuffle,
    required this.favorite,
    this.position = Duration.zero,
    required this.time,
  });

  factory _Sent.of(
    NowPlaying state, {
    required bool stopped,
    required bool favorite,
  }) => _Sent(
    playing: !stopped && state.isPlaying,
    processing: stopped
        ? AudioProcessingState.idle
        : state.isLoading
        ? AudioProcessingState.loading
        : state.isCompleted
        ? AudioProcessingState.completed
        : AudioProcessingState.ready,
    stopped: stopped,
    index: state.currentIndex,
    repeat: state.repeatMode,
    shuffle: state.shuffle,
    favorite: favorite,
    time: DateTime.fromMillisecondsSinceEpoch(0),
  );

  final bool playing;
  final AudioProcessingState processing;
  final bool stopped;
  final int? index;
  final PlaybackRepeat repeat;
  final bool shuffle;
  final bool favorite;
  final Duration position;
  final DateTime time;

  _Sent at(Duration position, DateTime time) => _Sent(
    playing: playing,
    processing: processing,
    stopped: stopped,
    index: index,
    repeat: repeat,
    shuffle: shuffle,
    favorite: favorite,
    position: position,
    time: time,
  );

  bool sameApartFromPosition(_Sent other) =>
      playing == other.playing &&
      processing == other.processing &&
      stopped == other.stopped &&
      index == other.index &&
      repeat == other.repeat &&
      shuffle == other.shuffle &&
      favorite == other.favorite;
}
