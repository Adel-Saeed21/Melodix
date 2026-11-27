import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/service/media_session_guest.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_song_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_song_favorite_usecase.dart';
import 'package:melodix/features/player/data/background/current_song_favorite.dart';
import 'package:melodix/features/player/data/background/media_controls.dart';
import 'package:melodix/features/player/data/background/now_playing_artwork_files.dart';
import 'package:melodix/features/player/data/background/session_states.dart';
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
///
/// **Video.** While a [MediaSessionGuest] (the video) owns the session, the
/// same controls show and drive it instead: play / pause, previous / next
/// and its own back / forward jumps. When the video is closed (or music
/// starts), the music gets them back as they were.
///
/// The parts with a job of their own: [MediaControls] (the buttons),
/// [CurrentSongFavorite] (the live ♥), and session_states.dart (what the
/// system shows: media items, playback states, when a position jumped).
class MelodixAudioHandler extends BaseAudioHandler {
  MelodixAudioHandler(
    this._player, {
    required this._artwork,
    required WatchSongFavoriteUseCase watchFavorite,
    required ToggleSongFavoriteUseCase toggleFavorite,
    MediaSessionGuest? guest,
    DateTime Function()? clock,
    AppLocalizations Function()? strings,
  }) : _guest = guest,
       _clock = clock ?? DateTime.now,
       _controls = MediaControls(strings ?? () => const AppLocalizations()),
       _strings = strings ?? (() => const AppLocalizations()) {
    _favorite = CurrentSongFavorite(
      watch: watchFavorite,
      toggle: toggleFavorite,
      onChanged: () => _send(_player.current),
    );
    _subscription = _player.watch().listen(_onNowPlaying);
    _progressSubscription = _player.watchProgress().listen(_onProgress);
    _guestSubscription = guest?.changes.listen(_onGuest);
  }

  final PlayerRepository _player;
  final NowPlayingArtworkFiles _artwork;
  final DateTime Function() _clock;
  final MediaControls _controls;

  /// The texts in the app's language now (labels follow a language change
  /// at the next update).
  final AppLocalizations Function() _strings;
  late final CurrentSongFavorite _favorite;
  final MediaSessionGuest? _guest;
  late final StreamSubscription<NowPlaying> _subscription;
  StreamSubscription<GuestMedia?>? _guestSubscription;
  late final StreamSubscription<PlaybackProgress> _progressSubscription;

  /// What was last sent for the guest, and when; null while the music
  /// owns the session.
  ({GuestMedia media, DateTime time})? _guestSent;

  /// The guest's state while it owns the session.
  GuestMedia? get _guestMedia => _guest?.current;

  /// Where playback is in the song (from the progress stream).
  Duration _position = Duration.zero;

  /// The last state sent to the system, to skip sending repeats.
  MusicSent? _sent;

  /// After [stop]: report idle (no notification) until playback resumes.
  bool _stopped = false;

  /// Custom action names (sent back by the system when tapped).
  static const String favoriteAction = MediaControls.favoriteAction;
  static const String shuffleAction = MediaControls.shuffleAction;
  static const String rewindAction = MediaControls.rewindAction;
  static const String forwardAction = MediaControls.forwardAction;

  // Commands from the system

  @override
  Future<void> play() {
    if (_guestMedia != null) return _guest!.play();
    _stopped = false;
    return _player.play();
  }

  @override
  Future<void> pause() =>
      _guestMedia != null ? _guest!.pause() : _player.pause();

  @override
  Future<void> seek(Duration position) =>
      _guestMedia != null ? _guest!.seek(position) : _player.seek(position);

  @override
  Future<void> skipToNext() =>
      _guestMedia != null ? _guest!.next() : _player.next();

  @override
  Future<void> skipToPrevious() =>
      _guestMedia != null ? _guest!.previous() : _player.previous();

  /// Headsets and cars with jump buttons: the video's back / forward (a
  /// song has none).
  @override
  Future<void> fastForward() async {
    if (_guestMedia != null) await _guest!.fastForward();
  }

  @override
  Future<void> rewind() async {
    if (_guestMedia != null) await _guest!.rewind();
  }

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

  /// The ♥ and shuffle buttons (the video's back / forward while it plays).
  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (_guestMedia != null) {
      switch (name) {
        case rewindAction:
          await _guest!.rewind();
        case forwardAction:
          await _guest!.fastForward();
      }
      return;
    }
    switch (name) {
      case favoriteAction:
        await _favorite.toggle();
      case shuffleAction:
        await _player.setShuffle(!_player.current.shuffle);
    }
  }

  /// Pauses and removes the notification (e.g. it was swiped away while
  /// paused). The song and position stay, ready to resume in the app.
  @override
  Future<void> stop() async {
    // The video's notification swiped away: it pauses (it stays open in
    // the app).
    if (_guestMedia != null) await _guest!.pause();
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
    await _guestSubscription?.cancel();
    await _favorite.dispose();
    await _progressSubscription.cancel();
    await _subscription.cancel();
  }

  // The music's state to the system

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
    // The video has the controls: the music waits its turn.
    if (_guestMedia != null) return;
    final song = _stopped ? null : state.currentSong;
    _favorite.follow(song);
    _sendMediaItem(song, state.duration);

    final now = _clock();
    final next = MusicSent.of(
      state,
      stopped: _stopped || song == null,
      favorite: _favorite.isFavorite,
    );
    final previous = _sent;
    if (!force &&
        previous != null &&
        previous.sameApartFromPosition(next) &&
        !positionJumped(
          position: _position,
          now: now,
          sentPosition: previous.position,
          sentAt: previous.time,
          playing: previous.playing,
        )) {
      return;
    }
    _sent = next.at(_position, now);
    playbackState.add(
      musicPlaybackState(
        state,
        next,
        controls: _controls,
        position: _position,
        now: now,
      ),
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
      songMediaItem(
        song,
        duration: duration,
        strings: _strings(),
        // Keep the cover while only the duration is corrected.
        artUri: sameSong ? current?.artUri : null,
      ),
    );
    if (sameSong) return;
    _addCoverWhenReady(id, _artwork.uriFor(song));
  }

  // The guest (video)

  void _onGuest(GuestMedia? media) {
    if (media == null) {
      if (_guestSent == null) return;
      // Back to the music, exactly as it is now.
      _guestSent = null;
      _sent = null;
      _send(_player.current, force: true);
      return;
    }
    _sendGuest(media);
  }

  /// Like [_send], for the guest: details when they change, the state
  /// when it changes or the position jumps.
  void _sendGuest(GuestMedia media) {
    final now = _clock();
    final previous = _guestSent;
    if (previous?.media.id != media.id ||
        previous?.media.title != media.title ||
        previous?.media.duration != media.duration) {
      _sendGuestItem(media);
    }
    if (previous != null &&
        previous.media.sameApartFromPosition(media) &&
        !positionJumped(
          position: media.position,
          now: now,
          sentPosition: previous.media.position,
          sentAt: previous.time,
          playing: previous.media.playing,
        )) {
      return;
    }
    _guestSent = (media: media, time: now);
    playbackState.add(guestPlaybackState(media, controls: _controls, now: now));
  }

  void _sendGuestItem(GuestMedia media) {
    final current = mediaItem.value;
    final sameItem = current?.id == media.id;
    // Keep the picture while only the duration is corrected.
    mediaItem.add(
      guestMediaItem(media, artUri: sameItem ? current?.artUri : null),
    );
    if (sameItem) return;
    final guest = _guest!;
    _addCoverWhenReady(
      media.id,
      _artwork.uriForKey(media.id, () => guest.artwork(media.id)),
    );
  }

  /// Adds the cover to the item showing once its file is ready (only if
  /// item [id] is still the one showing).
  void _addCoverWhenReady(String id, Future<Uri?> cover) => unawaited(
    cover.then((uri) {
      final latest = mediaItem.value;
      if (uri != null && latest != null && latest.id == id) {
        mediaItem.add(latest.copyWith(artUri: uri));
      }
    }),
  );
}
