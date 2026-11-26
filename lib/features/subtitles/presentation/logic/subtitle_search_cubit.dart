import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/subtitles/domain/entities/online_subtitle.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_failure.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_track.dart';
import 'package:melodix/features/subtitles/domain/usecases/subtitle_usecases.dart';

enum SubtitleSearchStatus { idle, loading, success, empty, failure }

class SubtitleSearchState extends Equatable {
  const SubtitleSearchState({
    this.status = SubtitleSearchStatus.idle,
    this.results = const [],
    this.failure,
    this.downloadingFileId,
    this.downloadFailure,
    this.savedFileIds = const {},
    this.remainingDownloads,
    this.resetsIn,
  });

  final SubtitleSearchStatus status;
  final List<OnlineSubtitle> results;

  /// Why the search failed ([SubtitleSearchStatus.failure]).
  final SubtitleFailure? failure;

  /// The result being downloaded (one at a time).
  final int? downloadingFileId;
  final SubtitleFailure? downloadFailure;

  /// Results kept on the device (downloaded in this search).
  final Set<int> savedFileIds;

  /// Downloads left today (after a download, as the service said).
  final int? remainingDownloads;
  final String? resetsIn;

  SubtitleSearchState copyWith({
    SubtitleSearchStatus? status,
    List<OnlineSubtitle>? results,
    SubtitleFailure? Function()? failure,
    int? Function()? downloadingFileId,
    SubtitleFailure? Function()? downloadFailure,
    Set<int>? savedFileIds,
    int? remainingDownloads,
    String? resetsIn,
  }) => SubtitleSearchState(
    status: status ?? this.status,
    results: results ?? this.results,
    failure: failure == null ? this.failure : failure(),
    downloadingFileId: downloadingFileId == null
        ? this.downloadingFileId
        : downloadingFileId(),
    downloadFailure: downloadFailure == null
        ? this.downloadFailure
        : downloadFailure(),
    savedFileIds: savedFileIds ?? this.savedFileIds,
    remainingDownloads: remainingDownloads ?? this.remainingDownloads,
    resetsIn: resetsIn ?? this.resetsIn,
  );

  @override
  List<Object?> get props => [
    status,
    results,
    failure,
    downloadingFileId,
    downloadFailure,
    savedFileIds,
    remainingDownloads,
    resetsIn,
  ];
}

/// Searching OpenSubtitles for a video and downloading a result (kept on
/// the device, then shown). One search and one download at a time: taps
/// while one runs are ignored (the service limits requests).
class SubtitleSearchCubit extends Cubit<SubtitleSearchState> {
  SubtitleSearchCubit({
    required this.videoId,
    required this._search,
    required this._download,
    required this._onDownloaded,
  }) : super(const SubtitleSearchState());

  final String videoId;
  final SearchOnlineSubtitlesUseCase _search;
  final DownloadSubtitleUseCase _download;

  /// A track just saved: the subtitles cubit adds and shows it.
  final Future<void> Function(SubtitleTrack track) _onDownloaded;

  bool get isAvailable => _search.isAvailable;

  Future<void> search(String query, {String? language}) async {
    if (state.status == SubtitleSearchStatus.loading) return;
    if (!_search.isAvailable) {
      emit(
        state.copyWith(
          status: SubtitleSearchStatus.failure,
          failure: () => const SubtitleNotConfiguredFailure(),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: SubtitleSearchStatus.loading,
        failure: () => null,
        downloadFailure: () => null,
      ),
    );
    final result = await _search(videoId, query: query, language: language);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SubtitleSearchStatus.failure,
          results: const [],
          failure: () => failure,
        ),
      ),
      (results) => emit(
        state.copyWith(
          status: results.isEmpty
              ? SubtitleSearchStatus.empty
              : SubtitleSearchStatus.success,
          results: results,
        ),
      ),
    );
  }

  Future<void> download(OnlineSubtitle subtitle) async {
    if (state.downloadingFileId != null) return;
    emit(
      state.copyWith(
        downloadingFileId: () => subtitle.fileId,
        downloadFailure: () => null,
      ),
    );
    final result = await _download(videoId, subtitle);
    if (isClosed) return;
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          downloadingFileId: () => null,
          downloadFailure: () => failure,
        ),
      ),
      (download) async {
        emit(
          state.copyWith(
            downloadingFileId: () => null,
            savedFileIds: {...state.savedFileIds, subtitle.fileId},
            remainingDownloads: download.remaining,
            resetsIn: download.resetsIn,
          ),
        );
        await _onDownloaded(download.track);
      },
    );
  }
}
