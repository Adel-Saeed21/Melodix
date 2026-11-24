import 'dart:async';

import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/entities/video_progress.dart';
import 'package:melodix/features/video/domain/usecases/get_video_playback_uri_usecase.dart';
import 'package:melodix/features/video/domain/usecases/video_progress_usecases.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:mocktail/mocktail.dart';

import 'package:melodix/core/service/playback_coordinator.dart';
import 'package:melodix/features/video/presentation/playback/video_progress_tracker.dart';

import '../../support/fake_video_engine.dart';

class MockPlaybackUri extends Mock implements GetVideoPlaybackUriUseCase {}

class MockRecordPlay extends Mock implements RecordVideoPlayUseCase {}

class MockSavePosition extends Mock implements SaveVideoPositionUseCase {}

class MockGetProgress extends Mock implements GetVideoProgressUseCase {}

Video testVideo(
  String id, {
  Duration length = const Duration(minutes: 10),
  bool favorite = false,
  int width = 1920,
  int height = 1080,
}) => Video(
  id: id,
  title: 'Video $id',
  duration: length,
  width: width,
  height: height,
  createdAt: DateTime(2026),
  isFavorite: favorite,
);

VideoProgress watched(String id, Duration position, {DateTime? at}) =>
    VideoProgress(videoId: id, position: position, lastPlayedAt: at);

/// Call from setUpAll in tests using [VideoPlayerHarness].
void registerVideoFallbacks() => registerFallbackValue(Duration.zero);

/// A [VideoPlayerCubit] over mocks and [FakeVideoEngine]s. Saved
/// positions are kept (with the repository's "finished" rule), so reopening
/// a video resumes where it was saved, as in the app.
class VideoPlayerHarness {
  VideoPlayerHarness({
    List<String> missing = const [],
    List<String> unplayable = const [],
    Map<String, Duration> saved = const {},
  }) {
    _saved.addAll(saved);
    when(() => playbackUri(any())).thenAnswer((call) async {
      final id = call.positionalArguments.first as String;
      return missing.contains(id) ? null : Uri.parse('content://video/$id');
    });
    when(() => recordPlay(any())).thenAnswer((_) async {});
    when(() => savePosition(any(), any(), length: any(named: 'length')))
        .thenAnswer((call) async {
          final id = call.positionalArguments[0] as String;
          final position = call.positionalArguments[1] as Duration;
          final length = call.namedArguments[#length] as Duration;
          _saved[id] = VideoProgress.isFinished(position, length)
              ? Duration.zero
              : position;
        });
    when(() => progress(any())).thenAnswer((call) async {
      final id = call.positionalArguments.first as String;
      final position = _saved[id];
      return position == null ? null : watched(id, position);
    });
    _unplayable = unplayable;
  }

  late final List<String> _unplayable;
  final Map<String, Duration> _saved = {};
  final playbackUri = MockPlaybackUri();
  final recordPlay = MockRecordPlay();
  final savePosition = MockSavePosition();
  final progress = MockGetProgress();
  final engines = <String, FakeVideoEngine>{};
  var musicPauses = 0;

  /// Whether music is playing (true: music started, the video pauses).
  final musicPlaying = StreamController<bool>.broadcast();

  /// Called for each new engine; may hold its load.
  FakeVideoEngine Function(Uri uri)? engineFor;

  VideoPlayerCubit cubit({Duration saveEvery = const Duration(seconds: 15)}) =>
      VideoPlayerCubit(
        playbackUri: playbackUri,
        progress: VideoProgressTracker(
          progress: progress,
          savePosition: savePosition,
          recordPlay: recordPlay,
          saveEvery: saveEvery,
        ),
        coordinator: PlaybackCoordinator(
          pauseMusic: () async => musicPauses++,
          musicPlaying: musicPlaying.stream,
        ),
        createEngine: (uri) {
          final id = uri.pathSegments.last;
          final engine =
              engineFor?.call(uri) ??
              FakeVideoEngine(uri, failInit: _unplayable.contains(id));
          engines[id] = engine;
          return engine;
        },
      );
}
