import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_cue.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_failure.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_track.dart';
import 'package:melodix/features/subtitles/domain/usecases/subtitle_usecases.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitle_search_cubit.dart';

/// [loading]: the tracks or the chosen track's captions are being read.
enum SubtitlesStatus { idle, loading, ready, failed }

class SubtitlesState extends Equatable {
  SubtitlesState({
    this.videoId,
    this.tracks = const [],
    this.selectedId,
    SubtitleTimeline? timeline,
    this.status = SubtitlesStatus.idle,
    this.failure,
    this.importing = false,
  }) : timeline = timeline ?? SubtitleTimeline.empty;

  /// The open video (null: none).
  final String? videoId;
  final List<SubtitleTrack> tracks;

  /// The track shown; null: subtitles off.
  final String? selectedId;

  /// The chosen track's captions (empty while off or loading).
  final SubtitleTimeline timeline;
  final SubtitlesStatus status;

  /// The last thing that went wrong (a broken file, a failed import).
  final SubtitleFailure? failure;
  final bool importing;

  SubtitleTrack? get selected {
    for (final track in tracks) {
      if (track.id == selectedId) return track;
    }
    return null;
  }

  bool get isOn => selectedId != null;

  SubtitlesState copyWith({
    List<SubtitleTrack>? tracks,
    String? Function()? selectedId,
    SubtitleTimeline? timeline,
    SubtitlesStatus? status,
    SubtitleFailure? Function()? failure,
    bool? importing,
  }) => SubtitlesState(
    videoId: videoId,
    tracks: tracks ?? this.tracks,
    selectedId: selectedId == null ? this.selectedId : selectedId(),
    timeline: timeline ?? this.timeline,
    status: status ?? this.status,
    failure: failure == null ? this.failure : failure(),
    importing: importing ?? this.importing,
  );

  @override
  List<Object?> get props => [
    videoId,
    tracks,
    selectedId,
    timeline,
    status,
    failure,
    importing,
  ];
}

/// The open video's subtitles: its tracks, the one chosen (remembered per
/// video) and its captions. Follows the video session: a new video loads
/// its own tracks and choice.
///
/// Everything is read from the device: once a track is saved, it works
/// offline.
class SubtitlesCubit extends Cubit<SubtitlesState> {
  SubtitlesCubit({
    required this._getTracks,
    required this._load,
    required this._selection,
    required this._import,
    this._search,
    this._download,
    required Stream<String?> currentVideo,
    String? initialVideo,
  }) : super(SubtitlesState()) {
    _videos = currentVideo.listen(openVideo);
    if (initialVideo != null) unawaited(openVideo(initialVideo));
  }

  final GetSubtitleTracksUseCase _getTracks;
  final LoadSubtitleUseCase _load;
  final SubtitleSelectionUseCase _selection;
  final ImportSubtitleUseCase _import;

  /// Online search (null: not offered).
  final SearchOnlineSubtitlesUseCase? _search;
  final DownloadSubtitleUseCase? _download;
  late final StreamSubscription<String?> _videos;

  /// Bumped on every video change and selection: older loads' answers are
  /// dropped.
  int _ticket = 0;

  bool get canImport => _import.isAvailable;

  /// Whether online search is set up in this build.
  bool get canSearchOnline =>
      _search != null && _download != null && _search.isAvailable;

  /// A search for the open video, whose downloads come back here (shown
  /// at once). Null when online search isn't available.
  SubtitleSearchCubit? createSearch() {
    final videoId = state.videoId;
    if (!canSearchOnline || videoId == null) return null;
    return SubtitleSearchCubit(
      videoId: videoId,
      search: _search!,
      download: _download!,
      onDownloaded: useTrack,
    );
  }

  /// Shows [videoId]'s subtitles (null: no video).
  Future<void> openVideo(String? videoId) async {
    if (videoId == state.videoId) return;
    final ticket = ++_ticket;
    emit(
      SubtitlesState(
        videoId: videoId,
        status: videoId == null
            ? SubtitlesStatus.idle
            : SubtitlesStatus.loading,
      ),
    );
    if (videoId == null) return;

    final tracks = await _getTracks(videoId);
    final chosen = await _selection.get(videoId);
    if (isClosed || ticket != _ticket) return;
    await tracks.fold(
      (failure) async => emit(
        state.copyWith(status: SubtitlesStatus.failed, failure: () => failure),
      ),
      (tracks) async {
        emit(state.copyWith(tracks: tracks));
        final track = tracks.where((t) => t.id == chosen).firstOrNull;
        await _show(track, ticket, remember: false);
      },
    );
  }

  /// Shows [track] (null: off), and remembers the choice for the video.
  Future<void> select(SubtitleTrack? track) async {
    if (state.videoId == null) return;
    await _show(track, ++_ticket, remember: true);
  }

  /// Picks a file from the device, keeps it and shows it.
  Future<void> importFromDevice() async {
    final videoId = state.videoId;
    if (videoId == null || state.importing) return;
    emit(state.copyWith(importing: true, failure: () => null));
    final result = await _import(videoId);
    if (isClosed || state.videoId != videoId) return;
    emit(state.copyWith(importing: false));
    await result.fold(
      (failure) async => emit(state.copyWith(failure: () => failure)),
      (track) async {
        if (track != null) await useTrack(track);
      },
    );
  }

  /// Adds [track] (just imported or downloaded) and shows it.
  Future<void> useTrack(SubtitleTrack track) async {
    if (track.videoId != state.videoId) return;
    emit(
      state.copyWith(
        tracks: [
          for (final t in state.tracks)
            if (t.id != track.id) t,
          track,
        ],
      ),
    );
    await _show(track, ++_ticket, remember: true);
  }

  Future<void> _show(
    SubtitleTrack? track,
    int ticket, {
    required bool remember,
  }) async {
    final videoId = state.videoId!;
    if (remember) await _selection.set(videoId, track?.id);
    if (isClosed || ticket != _ticket) return;
    if (track == null) {
      emit(
        state.copyWith(
          selectedId: () => null,
          timeline: SubtitleTimeline.empty,
          status: SubtitlesStatus.ready,
          failure: () => null,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        selectedId: () => track.id,
        timeline: SubtitleTimeline.empty,
        status: SubtitlesStatus.loading,
        failure: () => null,
      ),
    );
    final result = await _load(track);
    if (isClosed || ticket != _ticket) return;
    result.fold(
      // Unreadable: off, with the reason shown in the subtitles sheet.
      (failure) => emit(
        state.copyWith(
          selectedId: () => null,
          status: SubtitlesStatus.failed,
          failure: () => failure,
        ),
      ),
      (timeline) => emit(
        state.copyWith(timeline: timeline, status: SubtitlesStatus.ready),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _videos.cancel();
    return super.close();
  }
}
