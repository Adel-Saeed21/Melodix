import 'dart:async';
import 'dart:typed_data';

import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/service/media_session_guest.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';

/// The video session as a [MediaSessionGuest]: while a video plays, the
/// notification, lock screen and headset / Bluetooth buttons control it,
/// not the music.
///
/// Who owns the controls: the last to start playing.
/// * The video takes them when it starts playing (a paused video that was
///   only opened doesn't take them from the music).
/// * It keeps them while open, paused or not (pausing a video doesn't hand
///   the buttons back to a song the user isn't listening to).
/// * It gives them back when it's closed, or when music starts playing.
class VideoMediaSession implements MediaSessionGuest {
  VideoMediaSession({
    required this._session,
    required Stream<void> musicStarted,
    required this._seekStep,
    required this._thumbnail,
    AppLocalizations Function()? strings,
  }) : _strings = strings ?? (() => const AppLocalizations()) {
    _sessionSubscription = _session.stream.listen(_onSession);
    _musicSubscription = musicStarted.listen((_) => _setOwner(false));
    _onSession(_session.state);
  }

  final VideoPlayerCubit _session;

  /// The user's skip length (Settings), read at each jump.
  final Duration Function() _seekStep;

  /// A video's thumbnail bytes, for the notification's picture.
  final Future<Uint8List?> Function(String videoId) _thumbnail;

  /// The texts in the app's language now.
  final AppLocalizations Function() _strings;

  late final StreamSubscription<VideoPlayerState> _sessionSubscription;
  late final StreamSubscription<void> _musicSubscription;
  final StreamController<GuestMedia?> _changes =
      StreamController<GuestMedia?>.broadcast(sync: true);

  VideoEngine? _engine;
  bool _owns = false;
  GuestMedia? _current;

  /// Media ids are `video:<id>`: never mistaken for a song's.
  static const String idPrefix = 'video:';

  @override
  GuestMedia? get current => _current;

  @override
  Stream<GuestMedia?> get changes => _changes.stream;

  void _onSession(VideoPlayerState state) {
    final engine = state.isActive ? state.engine : null;
    if (!identical(engine, _engine)) {
      _engine?.removeListener(_onEngine);
      _engine = engine;
      engine?.addListener(_onEngine);
    }
    if (!state.isActive) {
      _setOwner(false);
      return;
    }
    if (engine?.value.isPlaying ?? false) _owns = true;
    _publish();
  }

  void _onEngine() {
    if (_engine?.value.isPlaying ?? false) _owns = true;
    _publish();
  }

  void _setOwner(bool owns) {
    _owns = owns;
    _publish();
  }

  void _publish() {
    final state = _session.state;
    final next = _owns && state.isActive ? _media(state, _engine) : null;
    if (next == _current) return;
    _current = next;
    _changes.add(next);
  }

  GuestMedia _media(VideoPlayerState state, VideoEngine? engine) {
    final video = state.video;
    final value = engine?.value;
    final ready = value != null && value.isInitialized;
    return GuestMedia(
      id: '$idPrefix${video.id}',
      title: video.title,
      subtitle: _strings().mediaVideoSubtitle,
      duration: ready && value.duration > Duration.zero
          ? value.duration
          : video.duration,
      position: value?.position ?? Duration.zero,
      playing: value?.isPlaying ?? false,
      loading:
          state.status == VideoPlayerStatus.loading ||
          (value?.isBuffering ?? false) && !(value?.isCompleted ?? false),
      completed: value?.isCompleted ?? false,
      hasNext: state.hasNext,
    );
  }

  @override
  Future<Uint8List?> artwork(String id) {
    if (!id.startsWith(idPrefix)) return Future.value();
    return _thumbnail(id.substring(idPrefix.length));
  }

  @override
  Future<void> play() async {
    final value = _engine?.value;
    if (value == null || value.isPlaying) return;
    await _session.togglePlayPause();
  }

  @override
  Future<void> pause() => _session.pause();

  @override
  Future<void> seek(Duration position) => _session.seek(position);

  @override
  Future<void> rewind() => _session.seekBy(-_seekStep());

  @override
  Future<void> fastForward() => _session.seekBy(_seekStep());

  @override
  Future<void> next() =>
      _session.state.hasNext ? _session.next() : fastForward();

  @override
  Future<void> previous() => _session.previous();

  Future<void> dispose() async {
    _engine?.removeListener(_onEngine);
    await _sessionSubscription.cancel();
    await _musicSubscription.cancel();
    await _changes.close();
  }
}
