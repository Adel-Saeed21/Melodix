import 'dart:async';
import 'dart:math';

import 'package:just_audio/just_audio.dart';
import 'package:melodix/core/database/playback_state_local_storage.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/core/utils/latest_value.dart';
import 'package:melodix/core/utils/serial_runner.dart';
import 'package:melodix/features/player/data/queue/loaded_window.dart';
import 'package:melodix/features/player/data/queue/pause_requests.dart';
import 'package:melodix/features/player/data/queue/playback_queue.dart';
import 'package:melodix/features/player/data/session/audio_focus.dart';
import 'package:melodix/features/player/data/session/play_counter.dart';
import 'package:melodix/features/player/data/session/playback_session_saver.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/entities/playback_error.dart';
import 'package:melodix/features/player/domain/entities/playback_progress.dart';
import 'package:melodix/features/player/domain/repositories/play_recorder.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';

/// Plays music with the app's single [AudioPlayer]: the playback commands,
/// the player's events and the state the app shows. Each song plays from its
/// content URI ([Song.playbackUri]).
///
/// The parts with a job of their own live in their own classes:
/// * [LoadedWindow]: the few songs just_audio holds around the current one,
///   kept in step with the whole queue (10,000 songs cost like an album);
/// * [PauseRequests]: a pause always wins over a load that's finishing;
/// * [AudioFocus]: the audio session (focus, ducking, headphones unplugged);
/// * [PlayCounter]: one play counted per song start ("Most played");
/// * [PlaybackSessionSaver]: the session saved for a restart.
///
/// All playlist changes run one at a time ([_serial]): a tap, Next or a
/// window update never overlaps another.
class PlayerRepositoryImpl implements PlayerRepository {
  PlayerRepositoryImpl({
    required this._player,
    required PlaybackStateLocalStorage sessionStorage,
    required PlayRecorder playRecorder,
    required this._mapper,
    AudioFocus? audioFocus,
    this.windowAhead = 4,
    this.windowBehind = 2,
    Random? random,
  }) : assert(windowAhead >= 2 && windowBehind >= 1),
       _session = PlaybackSessionSaver(sessionStorage),
       _plays = PlayCounter(playRecorder),
       _audioFocus = audioFocus ?? AudioFocus(),
       _random = random ?? Random() {
    _subscriptions.addAll([
      _player.playerStateStream.listen((_) => _onPlayerChanged()),
      _player.currentIndexStream.listen((_) => _onIndexChanged()),
      _player.positionStream.listen(_onPosition),
      _player.durationStream.listen((_) => _publish()),
      _player.loopModeStream.listen((_) => _publish()),
      _player.sequenceStateStream.listen((_) => _publish()),
      _player.errorStream.listen(_onPlaybackError),
    ]);
  }

  final AudioPlayer _player;
  final PlaybackSessionSaver _session;
  final PlayCounter _plays;
  final AudioFocus _audioFocus;
  final SongMapper _mapper;
  final Random _random;

  /// Songs kept loaded after / before the current one.
  final int windowAhead;
  final int windowBehind;

  final _pauses = PauseRequests();
  late final _window = LoadedWindow(
    _player,
    ahead: windowAhead,
    behind: windowBehind,
    repeat: () => _repeat,
    pauses: _pauses,
    onChanged: _publish,
    onLoadFailed: () => _reportError(PlaybackError.cannotPlay),
    onCurrentChanged: _onCurrentChanged,
  );
  late final _serial = SerialRunner(
    onIdle: () {
      _countPlay();
      _publish();
    },
  );

  final _state = LatestValue<NowPlaying>(NowPlaying.idle);
  final _progress = LatestValue<PlaybackProgress>(PlaybackProgress.zero);
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  String? _queueTitle;
  PlaybackRepeat _repeat = PlaybackRepeat.off;
  bool _shuffle = false;

  /// What to show while a new queue (tap or restore) is being loaded: the
  /// chosen song right away, never the previous song's index.
  _Pending? _pending;
  int _queueRequests = 0;
  bool _windowUpdateQueued = false;

  PlaybackError? _error;
  int _errorSequence = 0;

  /// Broken songs skipped in a row (reset once a song really plays), so a
  /// queue of broken files stops instead of skipping forever.
  int _consecutiveErrors = 0;
  static const int _maxSkipsOnError = 3;

  /// "Previous" restarts the song when it's further in than this.
  static const Duration _restartThreshold = Duration(seconds: 3);

  @override
  NowPlaying get current => _state.value;

  @override
  Stream<NowPlaying> watch() => _state.watch();

  @override
  PlaybackProgress get progress => _progress.value;

  @override
  Stream<PlaybackProgress> watchProgress() => _progress.watch();

  // Commands

  @override
  Future<void> playQueue(
    List<Song> songs, {
    int startIndex = 0,
    String? title,
    bool? shuffle,
  }) async {
    if (songs.isEmpty) return;
    final queueSongs = List<Song>.unmodifiable(songs);
    final index = startIndex.clamp(0, queueSongs.length - 1);
    final request = ++_queueRequests;
    final pauses = _pauses.mark();
    // Shuffle (or not) applies to the new queue directly: the old queue is
    // never reshuffled just to be replaced.
    if (shuffle != null && shuffle != _shuffle) {
      _shuffle = shuffle;
      _session.saveShuffle(shuffle);
    }
    // Show the tapped song immediately (before anything loads).
    _pending = _Pending(request, queueSongs, title, index, Duration.zero);
    _error = null;
    _publish();

    await _serial.run(() async {
      if (request != _queueRequests) return; // a newer tap replaced it
      await _activateAudio();
      final queue = _newQueue(queueSongs, index);
      _queueTitle = title;
      _plays.newQueue();
      final loaded = await _window.reload(queue.positionOf(index));
      if (request != _queueRequests) return; // replaced while loading
      _clearPending(request);
      if (!loaded) return;
      _session.saveQueue(queueSongs, currentIndex: index);
      if (_pauses.noneSince(pauses)) unawaited(_player.play());
    });
  }

  @override
  Future<void> playNext(List<Song> songs) => _addSongs(songs, next: true);

  @override
  Future<void> addToQueue(List<Song> songs) => _addSongs(songs, next: false);

  Future<void> _addSongs(List<Song> songs, {required bool next}) async {
    if (songs.isEmpty) return;
    // Nothing playing or on its way: these become the queue.
    if (_window.queue == null && _pending == null) return playQueue(songs);
    await _serial.run(() async {
      final queue = _window.queue;
      final slot = _window.current;
      if (queue == null || slot == null) return;
      final updated = queue.withAdded(
        songs,
        currentLogical: slot.logical,
        next: next,
      );
      _window.queue = updated;
      // Like a shuffle change: new neighbours, the current song untouched.
      await _window.reorderAround(updated.positionOf(slot.logical));
      _session.saveQueue(updated.songs, currentIndex: slot.logical);
    });
    _publish();
  }

  @override
  Future<void> play() async {
    if (_window.queue == null) return;
    final pauses = _pauses.mark();
    final ready = await _serial.run(() async {
      await _activateAudio();
      final slot = _window.current;
      if (slot == null) return false;
      if (_player.processingState == ProcessingState.completed) {
        // Finished the queue: start it again from the first song played.
        return _window.goTo(0);
      }
      if (_player.processingState == ProcessingState.idle) {
        // Restored or failed: (re)load before playing.
        return _window.reload(slot.position, start: _player.position);
      }
      return true;
    });
    if ((ready ?? false) && _pauses.noneSince(pauses)) {
      unawaited(_player.play());
    }
  }

  /// Pauses right away (not queued behind a load in progress) and makes
  /// sure that load doesn't start playback when it finishes.
  @override
  Future<void> pause() async {
    _pauses.record();
    await _player.pause();
    await _saveSession();
  }

  @override
  Future<void> seek(Duration position) async {
    final duration = _player.duration;
    var target = position.isNegative ? Duration.zero : position;
    if (duration != null && target > duration) target = duration;
    await _player.seek(target);
    unawaited(_saveSession());
  }

  @override
  Future<void> skipToIndex(int index) async {
    final pauses = _pauses.mark();
    final ready = await _serial.run(() async {
      final queue = _window.queue;
      if (queue == null || index < 0 || index >= queue.length) return false;
      await _activateAudio();
      if (_player.processingState == ProcessingState.idle) {
        return _window.reload(queue.positionOf(index));
      }
      return _window.goToLogical(index);
    });
    if ((ready ?? false) && _pauses.noneSince(pauses)) {
      unawaited(_player.play());
    }
  }

  @override
  Future<void> next() => _serial.run(() async {
    final slot = _window.current;
    if (slot == null) return;
    // Like the player's own "next" with repeat one: restart the song.
    if (_repeat == PlaybackRepeat.one) return _player.seek(Duration.zero);
    if (!_window.hasNext(slot.position)) return;
    await _window.goTo(slot.position + 1);
  });

  @override
  Future<void> previous() => _serial.run(() async {
    final slot = _window.current;
    if (slot == null) return;
    if (_repeat == PlaybackRepeat.one ||
        _player.position > _restartThreshold ||
        !_window.hasPrevious(slot.position)) {
      return _player.seek(Duration.zero);
    }
    await _window.goTo(slot.position - 1);
  });

  @override
  Future<void> setRepeatMode(PlaybackRepeat mode) async {
    await _serial.run(() async {
      final before = _repeat;
      _repeat = mode;
      await _window.applyLoopMode();
      if (_window.queue != null &&
          !_window.fitsWhole &&
          _window.current != null) {
        // Positions past either end only exist while repeating everything.
        if (before == PlaybackRepeat.all && mode != PlaybackRepeat.all) {
          _window.leaveRepeatAll();
        }
        await _window.keepFilled();
      }
    });
    _session.saveRepeat(mode);
  }

  @override
  Future<void> setShuffle(bool enabled) async {
    await _serial.run(() async {
      _shuffle = enabled;
      final queue = _window.queue;
      final slot = _window.current;
      if (queue == null || slot == null) return;
      // A new stable order over the whole queue (the current song first),
      // or the queue's own order back. Only the neighbours change; the
      // current song keeps playing.
      enabled
          ? queue.shuffle(firstLogical: slot.logical, random: _random)
          : queue.unshuffle();
      await _window.reorderAround(queue.positionOf(slot.logical));
    });
    _session.saveShuffle(enabled);
  }

  @override
  Future<void> restoreLastSession() async {
    if (_window.queue != null || _pending != null) return;
    final saved = await _session.load();
    if (saved == null || saved.queue.isEmpty) return;
    if (_window.queue != null || _pending != null) return; // a tap came first
    final songs = List<Song>.unmodifiable(saved.queue.map(_mapper.toEntity));
    final index = saved.currentIndex.clamp(0, songs.length - 1);
    final request = ++_queueRequests;
    _repeat = PlaybackSessionSaver.fromStored(saved.repeatMode);
    _shuffle = saved.shuffle;
    // Show the saved song and position right away while it loads.
    _pending = _Pending(request, songs, null, index, saved.position);
    _publish();

    await _serial.run(() async {
      if (request != _queueRequests) return;
      final queue = _newQueue(songs, index);
      _queueTitle = null;
      _plays
        ..newQueue()
        // Resuming the restored song isn't a new play.
        ..alreadyCounted(index);
      try {
        await _window.reload(queue.positionOf(index), start: saved.position);
      } finally {
        _clearPending(request);
      }
    });
  }

  PlaybackQueue _newQueue(List<Song> songs, int startIndex) =>
      _window.queue = PlaybackQueue(
        songs,
        startIndex: startIndex,
        shuffled: _shuffle,
        random: _random,
      );

  void _scheduleWindowUpdate() {
    if (_windowUpdateQueued) return;
    _windowUpdateQueued = true;
    unawaited(
      _serial.run(() async {
        _windowUpdateQueued = false;
        await _window.keepFilled();
      }),
    );
  }

  // Player events

  void _onPosition(Duration position) {
    // A song is really playing: broken songs are no longer "in a row".
    if (_consecutiveErrors > 0 && position > const Duration(seconds: 2)) {
      _consecutiveErrors = 0;
    }
    _publishProgress();
  }

  void _onPlayerChanged() {
    final playing =
        _player.playing && _player.processingState != ProcessingState.completed;
    if (playing) {
      _session.whilePlaying(_saveSession);
      _countPlay();
    } else {
      _session.stopped();
    }
    _publish();
  }

  /// A song failed while playing (e.g. its file was deleted or is damaged):
  /// say so and go on with the next song, like other players. After
  /// [_maxSkipsOnError] broken songs in a row, or at the end of the queue,
  /// it stops instead.
  void _onPlaybackError(PlayerException error) {
    // During our own loads the load reports it; a load that already failed
    // and said so isn't reported twice.
    if (_serial.isBusy || _pending != null || _window.lastLoadFailed) return;
    final failed = _window.slotAt(error.index);
    if (_window.queue == null || failed == null) return;

    _reportError(PlaybackError.cannotPlay);
    final next = _window.nextAfter(failed.position);
    if (next == null || _consecutiveErrors >= _maxSkipsOnError) {
      _consecutiveErrors = 0;
      unawaited(_player.pause());
      return;
    }
    _consecutiveErrors++;
    final pauses = _pauses.mark();
    unawaited(
      _serial.run(() async {
        // A fresh load: after an error the native player must be prepared
        // again, so a plain seek isn't enough.
        if (await _window.reload(next) && _pauses.noneSince(pauses)) {
          unawaited(_player.play());
        }
      }),
    );
  }

  /// The player moved by itself (a song ended): follow it. Index changes
  /// during our own operations are handled by the operation.
  void _onIndexChanged() {
    if (!_serial.isBusy && _window.followPlayer()) {
      _onCurrentChanged();
      _scheduleWindowUpdate();
    }
    _publish();
  }

  void _onCurrentChanged() {
    _countPlay();
    unawaited(_saveSession());
  }

  /// Counts one play when a song starts playing (once per start).
  void _countPlay() {
    final slot = _window.current;
    if (_serial.isBusy || _pending != null || slot == null) return;
    if (!_player.playing) return;
    _plays.playing(
      logical: slot.logical,
      songId: _window.queue!.songs[slot.logical].id,
    );
  }

  Future<void> _saveSession() async {
    final slot = _window.current;
    if (_window.queue == null || slot == null || _pending != null) return;
    await _session.savePosition(
      currentIndex: slot.logical,
      position: _player.position,
    );
  }

  /// Headphones unplugged goes through [pause] (see [AudioFocus.activate]).
  Future<void> _activateAudio() =>
      _audioFocus.activate(onBecomingNoisy: () => unawaited(pause()));

  void _clearPending(int request) {
    if (_pending?.request != request) return;
    _pending = null;
    _publish();
  }

  void _reportError(PlaybackError error) {
    _error = error;
    _errorSequence++;
    _publish();
  }

  // State

  /// Sends the player state if it changed, then the progress (both can
  /// change together, e.g. a new song).
  void _publish() {
    _state.set(_buildState());
    _publishProgress();
  }

  NowPlaying _buildState() {
    final pending = _pending;
    if (pending != null) {
      final song = pending.songs[pending.index];
      // The tapped song starts the order when shuffling.
      final position = _shuffle ? 0 : pending.index;
      final n = pending.songs.length;
      return NowPlaying(
        queue: pending.songs,
        queueTitle: pending.title,
        currentIndex: pending.index,
        isPlaying: _player.playing,
        isLoading: true,
        duration: song.duration,
        repeatMode: _repeat,
        shuffle: _shuffle,
        hasNext: _repeat != PlaybackRepeat.off || position < n - 1,
        hasPrevious: _repeat != PlaybackRepeat.off || position > 0,
        error: _error,
        errorSequence: _errorSequence,
      );
    }
    final queue = _window.queue;
    final slot = queue == null ? null : _window.current;
    final processing = _player.processingState;
    final completed = processing == ProcessingState.completed;
    return NowPlaying(
      queue: queue?.songs ?? const [],
      queueTitle: _queueTitle,
      currentIndex: slot?.logical,
      isPlaying: _player.playing && !completed,
      isLoading:
          _window.loadingFrom != null ||
          processing == ProcessingState.loading ||
          processing == ProcessingState.buffering,
      isCompleted: completed,
      duration: _currentDuration(),
      repeatMode: _repeat,
      shuffle: _shuffle,
      hasNext: slot != null && _window.hasNext(slot.position),
      hasPrevious: slot != null && _window.hasPrevious(slot.position),
      error: _error,
      errorSequence: _errorSequence,
    );
  }

  /// The current song's length: its saved length while it loads, then the
  /// player's.
  Duration _currentDuration() {
    final pending = _pending;
    if (pending != null) return pending.songs[pending.index].duration;
    final queue = _window.queue;
    final slot = queue == null ? null : _window.current;
    if (_window.loadingFrom != null && slot != null) {
      return queue!.songs[slot.logical].duration;
    }
    return _player.duration ?? Duration.zero;
  }

  /// Sends where playback is, if it moved: the chosen start while a song
  /// loads, the player's position otherwise.
  void _publishProgress() => _progress.set(
    PlaybackProgress(
      position: _pending?.position ?? _window.loadingFrom ?? _player.position,
      duration: _currentDuration(),
    ),
  );
}

/// A queue chosen (tap or restore) but not loaded yet.
class _Pending {
  const _Pending(
    this.request,
    this.songs,
    this.title,
    this.index,
    this.position,
  );

  final int request;
  final List<Song> songs;
  final String? title;
  final int index;
  final Duration position;
}
