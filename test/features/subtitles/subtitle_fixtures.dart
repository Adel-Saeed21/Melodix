import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:melodix/features/subtitles/domain/entities/online_subtitle.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_cue.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_download.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_failure.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_track.dart';
import 'package:melodix/features/subtitles/domain/repositories/subtitle_repository.dart';
import 'package:melodix/features/subtitles/domain/usecases/subtitle_usecases.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitles_cubit.dart';

SubtitleTrack testTrack(
  String id, {
  String videoId = 'a',
  SubtitleSource source = SubtitleSource.imported,
}) => SubtitleTrack(
  id: id,
  videoId: videoId,
  label: '$id.srt',
  source: source,
  path: '/subs/$id.srt',
);

SubtitleTimeline timelineOf(String text) => SubtitleTimeline([
  SubtitleCue(
    start: const Duration(seconds: 1),
    end: const Duration(seconds: 4),
    text: text,
  ),
]);

/// An in-memory [SubtitleRepository].
class FakeSubtitleRepository implements SubtitleRepository {
  final tracks = <String, List<SubtitleTrack>>{};
  final timelines = <String, SubtitleTimeline>{};
  final selected = <String, String?>{};
  final unreadable = <String>{};
  SubtitleFailure? tracksFailure;
  SubtitleTrack? toImport;
  Either<SubtitleFailure, List<OnlineSubtitle>> searchResult = const Right([]);
  Either<SubtitleFailure, SubtitleDownload>? downloadResult;

  /// (query, language) per search; IMDb searches in [imdbSearches].
  final searches = <(String?, String?)>[];
  final imdbSearches = <int>[];

  /// Holds [load] until completed (to test stale answers).
  Completer<void>? loadGate;

  @override
  bool canImport = true;

  @override
  bool canSearchOnline = true;

  @override
  Future<Either<SubtitleFailure, List<SubtitleTrack>>> tracksFor(
    String videoId,
  ) async {
    final failure = tracksFailure;
    if (failure != null) return Left(failure);
    return Right(tracks[videoId] ?? const []);
  }

  @override
  Future<Either<SubtitleFailure, SubtitleTimeline>> load(
    SubtitleTrack track,
  ) async {
    await loadGate?.future;
    if (unreadable.contains(track.id)) {
      return const Left(SubtitleFormatFailure());
    }
    return Right(timelines[track.id] ?? timelineOf(track.id));
  }

  @override
  Future<String?> selectedTrackId(String videoId) async => selected[videoId];

  @override
  Future<void> setSelectedTrackId(String videoId, String? trackId) async =>
      selected[videoId] = trackId;

  @override
  Future<Either<SubtitleFailure, SubtitleTrack?>> importFromDevice(
    String videoId,
  ) async => Right(toImport);

  @override
  Future<Either<SubtitleFailure, List<OnlineSubtitle>>> searchOnline(
    String videoId, {
    String? query,
    int? imdbId,
    String? language,
  }) async {
    if (imdbId != null) imdbSearches.add(imdbId);
    searches.add((query, language));
    return searchResult;
  }

  @override
  Future<Either<SubtitleFailure, SubtitleDownload>> download(
    String videoId,
    OnlineSubtitle subtitle,
  ) async => downloadResult!;
}

SubtitlesCubit subtitlesCubitOver(
  SubtitleRepository repository, {
  Stream<String?> currentVideo = const Stream.empty(),
  String? initialVideo,
}) => SubtitlesCubit(
  getTracks: GetSubtitleTracksUseCase(repository),
  load: LoadSubtitleUseCase(repository),
  selection: SubtitleSelectionUseCase(repository),
  import: ImportSubtitleUseCase(repository),
  search: SearchOnlineSubtitlesUseCase(repository),
  download: DownloadSubtitleUseCase(repository),
  currentVideo: currentVideo,
  initialVideo: initialVideo,
);
