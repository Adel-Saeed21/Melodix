// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

/// The native side of just_audio, simulated: keeps the playlist exactly as
/// the real [AudioPlayer] sends it (load, insert, remove), plays it with
/// loop modes, and lets tests finish songs, hold operations open (to create
/// races) and inspect what is really loaded and playing.
///
/// Install with [FakeAudioNative.install] before creating an AudioPlayer.
class FakeAudioNative extends JustAudioPlatform {
  FakeAudioNative._();

  static FakeAudioNative install() {
    final native = FakeAudioNative._();
    JustAudioPlatform.instance = native;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'com.ryanheise.audio_session',
      'com.ryanheise.android_audio_manager',
      'com.ryanheise.av_audio_session',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    return native;
  }

  FakeNativePlayer? player;

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async =>
      player = FakeNativePlayer(request.id);

  @override
  Future<DisposePlayerResponse> disposePlayer(DisposePlayerRequest r) async =>
      DisposePlayerResponse();

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest r,
  ) async => DisposeAllPlayersResponse();
}

class FakeNativePlayer extends AudioPlayerPlatform {
  FakeNativePlayer(super.id);

  final _events = StreamController<PlaybackEventMessage>.broadcast();

  /// The loaded playlist, as content URIs.
  final List<String> playlist = [];
  int index = 0;
  Duration position = Duration.zero;
  ProcessingStateMessage state = ProcessingStateMessage.idle;
  bool playing = false;
  LoopModeMessage loopMode = LoopModeMessage.off;

  // Counters for tests and benchmarks.
  int loads = 0;
  int inserts = 0;
  int removes = 0;
  int sourcesReceived = 0;
  final List<int> loadSizes = [];

  /// When set, the next load / insert / remove waits for it (a slow native
  /// side), so tests can act while a playlist change is in flight.
  Completer<void>? holdLoad;
  Completer<void>? holdUpdate;

  /// Song id of a content URI (the last path segment).
  static int idOf(String uri) => int.parse(uri.split('/').last);

  int? get currentSongId => playlist.isEmpty || index >= playlist.length
      ? null
      : idOf(playlist[index]);

  int get playlistUpdates => inserts + removes;

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => _events.stream;

  void _emit() => _events.add(
    PlaybackEventMessage(
      processingState: state,
      updateTime: DateTime.now(),
      updatePosition: position,
      bufferedPosition: position,
      duration: const Duration(minutes: 3),
      icyMetadata: null,
      currentIndex: playlist.isEmpty ? null : index,
      androidAudioSessionId: null,
    ),
  );

  static List<String> _uris(List<AudioSourceMessage> messages) => [
    for (final m in messages)
      if (m is ConcatenatingAudioSourceMessage)
        ..._uris(m.children)
      else if (m is UriAudioSourceMessage)
        m.uri,
  ];

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    final uris = _uris([request.audioSourceMessage]);
    loads++;
    loadSizes.add(uris.length);
    sourcesReceived += uris.length;
    state = ProcessingStateMessage.loading;
    _emit();
    final hold = holdLoad;
    if (hold != null) {
      holdLoad = null;
      await hold.future;
    }
    playlist
      ..clear()
      ..addAll(uris);
    index = request.initialIndex ?? 0;
    position = request.initialPosition ?? Duration.zero;
    state = ProcessingStateMessage.ready;
    _emit();
    return LoadResponse(duration: const Duration(minutes: 3));
  }

  Future<void> _holdUpdate() async {
    final hold = holdUpdate;
    if (hold != null) {
      holdUpdate = null;
      await hold.future;
    }
  }

  @override
  Future<ConcatenatingInsertAllResponse> concatenatingInsertAll(
    ConcatenatingInsertAllRequest request,
  ) async {
    await _holdUpdate();
    final uris = _uris(request.children);
    inserts++;
    sourcesReceived += uris.length;
    playlist.insertAll(request.index, uris);
    if (request.index <= index && playlist.length > uris.length) {
      index += uris.length; // ExoPlayer keeps playing the same item
    }
    _emit();
    return ConcatenatingInsertAllResponse();
  }

  @override
  Future<ConcatenatingRemoveRangeResponse> concatenatingRemoveRange(
    ConcatenatingRemoveRangeRequest request,
  ) async {
    await _holdUpdate();
    removes++;
    final start = request.startIndex, end = request.endIndex;
    if (index >= start && index < end) {
      throw StateError('removed the playing item');
    }
    playlist.removeRange(start, end);
    if (index >= end) index -= end - start;
    _emit();
    return ConcatenatingRemoveRangeResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    if (request.index != null) index = request.index!;
    position = request.position ?? Duration.zero;
    if (state == ProcessingStateMessage.completed) {
      state = ProcessingStateMessage.ready;
    }
    _emit();
    return SeekResponse();
  }

  /// The current song plays to its end; the player moves on like ExoPlayer.
  void finishSong() {
    position = Duration.zero;
    if (loopMode == LoopModeMessage.one) {
      // Same item again.
    } else if (index + 1 < playlist.length) {
      index++;
    } else if (loopMode == LoopModeMessage.all) {
      index = 0;
    } else {
      state = ProcessingStateMessage.completed;
    }
    _emit();
  }

  /// Playback moved on by [elapsed] inside the current song.
  void advance(Duration elapsed) {
    position += elapsed;
    _emit();
  }

  /// Called when the app asks the native side to play (for benchmarks).
  void Function()? onPlay;

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    playing = true;
    onPlay?.call();
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    playing = false;
    return PauseResponse();
  }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest r) async {
    loopMode = r.loopMode;
    return SetLoopModeResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest r) async =>
      SetVolumeResponse();
  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest r) async =>
      SetSpeedResponse();
  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest r) async =>
      SetPitchResponse();
  @override
  Future<SetSkipSilenceResponse> setSkipSilence(
    SetSkipSilenceRequest r,
  ) async => SetSkipSilenceResponse();
  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest r,
  ) async => SetShuffleModeResponse();
  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(
    SetShuffleOrderRequest r,
  ) async => SetShuffleOrderResponse();
  @override
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse>
  setAutomaticallyWaitsToMinimizeStalling(
    SetAutomaticallyWaitsToMinimizeStallingRequest r,
  ) async => SetAutomaticallyWaitsToMinimizeStallingResponse();
  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
    SetAndroidAudioAttributesRequest r,
  ) async => SetAndroidAudioAttributesResponse();
  @override
  Future<DisposeResponse> dispose(DisposeRequest r) async => DisposeResponse();
}
