import 'package:melodix/core/models/load_status.dart';

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/usecases/toggle_video_favorite_usecase.dart';
import 'package:melodix/features/video/domain/usecases/video_bulk_usecases.dart';
import 'package:melodix/features/video/domain/usecases/watch_favorite_videos_usecase.dart';

class FavoriteVideosState extends Equatable {
  const FavoriteVideosState({
    this.status = LoadStatus.loading,
    this.videos = const [],
    this.ids = const {},
    this.errorMessage,
  });

  final LoadStatus status;
  final List<Video> videos;

  /// The favourites' ids: "is this one a favourite?" at a glance.
  final Set<String> ids;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, videos, ids, errorMessage];
}

/// The app's favourite videos, live, and the one way to (un)favourite a
/// video: the Videos tab, the Favourites page and the player all use it,
/// so a ♥ anywhere shows everywhere at once.
class FavoriteVideosCubit extends Cubit<FavoriteVideosState> {
  FavoriteVideosCubit({
    required WatchFavoriteVideosUseCase watchFavorites,
    required this._toggleFavorite,
    required this._setFavorite,
  }) : super(const FavoriteVideosState()) {
    _subscription = watchFavorites().listen(
      (videos) => emit(
        FavoriteVideosState(
          status: LoadStatus.ready,
          videos: videos,
          ids: {for (final v in videos) v.id},
        ),
      ),
      onError: (Object _) => emit(
        FavoriteVideosState(
          status: LoadStatus.failure,
          videos: state.videos,
          ids: state.ids,
          errorMessage: AppStrings.videoScanFailed,
        ),
      ),
    );
  }

  final ToggleVideoFavoriteUseCase _toggleFavorite;
  final SetVideosFavoriteUseCase _setFavorite;
  late final StreamSubscription<List<Video>> _subscription;

  /// Flips [videoId]'s favourite flag. Returns the new value, or null if it
  /// couldn't be saved (the list is unchanged then).
  Future<bool?> toggleFavorite(String videoId) async {
    final result = await _toggleFavorite(videoId);
    return result.fold((_) => null, (isFavorite) => isFavorite);
  }

  /// Makes all [videoIds] favourites (or none of them). False if it
  /// couldn't be saved.
  Future<bool> setFavorite(
    List<String> videoIds, {
    required bool favorite,
  }) async {
    final result = await _setFavorite(videoIds, favorite: favorite);
    return result.isRight();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
