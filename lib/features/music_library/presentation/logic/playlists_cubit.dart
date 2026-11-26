import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/usecases/create_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/delete_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/rename_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_playlist_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_playlists_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/action_feedback.dart';

class PlaylistsState extends Equatable {
  const PlaylistsState({
    this.isLoading = true,
    this.playlists = const [],
    this.feedback,
  });

  final bool isLoading;
  final List<Playlist> playlists;

  /// The latest action's message (null until the first action).
  final ActionFeedback? feedback;

  Playlist? byId(int id) {
    for (final playlist in playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  PlaylistsState copyWith({
    bool? isLoading,
    List<Playlist>? playlists,
    ActionFeedback? feedback,
  }) {
    return PlaylistsState(
      isLoading: isLoading ?? this.isLoading,
      playlists: playlists ?? this.playlists,
      feedback: feedback ?? this.feedback,
    );
  }

  @override
  List<Object?> get props => [isLoading, playlists, feedback];
}

class PlaylistsCubit extends Cubit<PlaylistsState>
    with ActionFeedbackReporter<PlaylistsState> {
  PlaylistsCubit({
    required WatchPlaylistsUseCase watchPlaylists,
    required this._createPlaylist,
    required this._renamePlaylist,
    required this._deletePlaylist,
    required this._toggleFavorite,
  }) : super(const PlaylistsState()) {
    _subscription = watchPlaylists().listen(
      (playlists) =>
          emit(state.copyWith(isLoading: false, playlists: playlists)),
      onError: _onWatchError,
    );
  }

  final CreatePlaylistUseCase _createPlaylist;
  final RenamePlaylistUseCase _renamePlaylist;
  final DeletePlaylistUseCase _deletePlaylist;
  final TogglePlaylistFavoriteUseCase _toggleFavorite;
  late final StreamSubscription<List<Playlist>> _subscription;

  @override
  PlaylistsState withFeedback(ActionFeedback feedback) =>
      state.copyWith(feedback: feedback);

  /// Keeps the playlists already shown (or stops the spinner) and tells
  /// the user, instead of an unhandled stream error.
  void _onWatchError(Object error, StackTrace stackTrace) {
    addError(error, stackTrace);
    if (isClosed) return;
    if (state.isLoading) emit(state.copyWith(isLoading: false));
    report(AppStrings.playlistsLoadFailed, isError: true);
  }

  Future<void> create(String name) async {
    final trimmed = name.trim();
    reportResult(
      await _createPlaylist(CreatePlaylistParams(trimmed)),
      (_) => AppStrings.playlistCreated(trimmed),
    );
  }

  Future<void> rename(Playlist playlist, String name) async {
    reportResult(
      await _renamePlaylist(RenamePlaylistParams(playlist.id, name.trim())),
      (_) => AppStrings.playlistRenamed,
    );
  }

  Future<void> delete(Playlist playlist) async {
    reportResult(
      await _deletePlaylist(playlist.id),
      (_) => AppStrings.playlistDeleted,
    );
  }

  Future<void> toggleFavorite(Playlist playlist) async {
    reportResult(
      await _toggleFavorite(playlist.id),
      (isFavorite) => isFavorite
          ? AppStrings.playlistAddedToFavourites
          : AppStrings.playlistRemovedFromFavourites,
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
