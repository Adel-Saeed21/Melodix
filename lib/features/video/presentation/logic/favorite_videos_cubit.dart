import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/usecases/toggle_video_favorite_usecase.dart';
import 'package:melodix/features/video/domain/usecases/watch_favorite_videos_usecase.dart';

class FavoriteVideosState extends Equatable {
  const FavoriteVideosState({
    this.status = LoadStatus.loading,
    this.videos = const [],
    this.errorMessage,
  });

  final LoadStatus status;
  final List<Video> videos;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, videos, errorMessage];
}

/// The favourite videos, live: a video ♥'d anywhere appears at once, and
/// leaves when it's unfavourited.
class FavoriteVideosCubit extends Cubit<FavoriteVideosState> {
  FavoriteVideosCubit({
    required WatchFavoriteVideosUseCase watchFavorites,
    required this._toggleFavorite,
  }) : super(const FavoriteVideosState()) {
    _subscription = watchFavorites().listen(
      (videos) =>
          emit(FavoriteVideosState(status: LoadStatus.ready, videos: videos)),
      onError: (Object _) => emit(
        FavoriteVideosState(
          status: LoadStatus.failure,
          videos: state.videos,
          errorMessage: _loadError,
        ),
      ),
    );
  }

  static const String _loadError = 'Could not read your videos';

  final ToggleVideoFavoriteUseCase _toggleFavorite;
  late final StreamSubscription<List<Video>> _subscription;

  /// Flips [videoId]'s favourite flag. Returns the new value, or null if it
  /// couldn't be saved (the list is unchanged then).
  Future<bool?> toggleFavorite(String videoId) async {
    final result = await _toggleFavorite(videoId);
    return result.fold((_) => null, (isFavorite) => isFavorite);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
