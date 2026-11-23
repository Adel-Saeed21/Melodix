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

class PlaylistsState extends Equatable {
  const PlaylistsState({
    this.isLoading = true,
    this.playlists = const [],
    this.message,
    this.messageSequence = 0,
  });

  final bool isLoading;
  final List<Playlist> playlists;

  final String? message;

  final int messageSequence;

  Playlist? byId(int id) {
    for (final playlist in playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  PlaylistsState copyWith({
    bool? isLoading,
    List<Playlist>? playlists,
    String? message,
    int? messageSequence,
  }) {
    return PlaylistsState(
      isLoading: isLoading ?? this.isLoading,
      playlists: playlists ?? this.playlists,
      message: message ?? this.message,
      messageSequence: messageSequence ?? this.messageSequence,
    );
  }

  @override
  List<Object?> get props => [isLoading, playlists, message, messageSequence];
}

class PlaylistsCubit extends Cubit<PlaylistsState> {
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
    );
  }

  final CreatePlaylistUseCase _createPlaylist;
  final RenamePlaylistUseCase _renamePlaylist;
  final DeletePlaylistUseCase _deletePlaylist;
  final TogglePlaylistFavoriteUseCase _toggleFavorite;
  late final StreamSubscription<List<Playlist>> _subscription;

  Future<void> create(String name) async {
    final trimmed = name.trim();
    final result = await _createPlaylist(CreatePlaylistParams(trimmed));
    _report(
      result.fold((f) => f.message, (_) => AppStrings.playlistCreated(trimmed)),
    );
  }

  Future<void> rename(Playlist playlist, String name) async {
    final result = await _renamePlaylist(
      RenamePlaylistParams(playlist.id, name.trim()),
    );
    _report(result.fold((f) => f.message, (_) => AppStrings.playlistRenamed));
  }

  Future<void> delete(Playlist playlist) async {
    final result = await _deletePlaylist(playlist.id);
    _report(result.fold((f) => f.message, (_) => AppStrings.playlistDeleted));
  }

  Future<void> toggleFavorite(Playlist playlist) async {
    final result = await _toggleFavorite(playlist.id);
    _report(
      result.fold(
        (f) => f.message,
        (isFavorite) => isFavorite
            ? AppStrings.playlistAddedToFavourites
            : AppStrings.playlistRemovedFromFavourites,
      ),
    );
  }

  void _report(String message) {
    if (isClosed) return;
    emit(
      state.copyWith(
        message: message,
        messageSequence: state.messageSequence + 1,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
