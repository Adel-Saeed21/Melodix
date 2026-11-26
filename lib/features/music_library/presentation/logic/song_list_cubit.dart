import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';

class SongListState extends Equatable {
  const SongListState({
    this.status = LoadStatus.loading,
    this.songs = const [],
    this.errorMessage,
    this.reorderFailures = 0,
  });

  final LoadStatus status;
  final List<Song> songs;
  final String? errorMessage;

  /// Increases each time saving a new order fails (to show a message).
  final int reorderFailures;

  @override
  List<Object?> get props => [status, songs, errorMessage, reorderFailures];
}

/// Loads one list of songs, e.g. an album's or an artist's songs.
class SongListCubit extends Cubit<SongListState> {
  SongListCubit(this._loadSongs, {this.saveOrder})
    : super(const SongListState());

  final Future<Either<Failure, List<Song>>> Function() _loadSongs;

  /// Persists a new song order (e.g. for a playlist). When null, the list
  /// can't be reordered.
  final Future<Either<Failure, Unit>> Function(List<Song> songs)? saveOrder;

  bool get canReorder => saveOrder != null;

  Future<void> load() async {
    final result = await _loadSongs();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => SongListState(
          status: LoadStatus.failure,
          songs: state.songs,
          errorMessage: failure.message,
          reorderFailures: state.reorderFailures,
        ),
        (songs) => SongListState(
          status: LoadStatus.ready,
          songs: songs,
          reorderFailures: state.reorderFailures,
        ),
      ),
    );
  }

  /// Moves the song at [oldIndex] so it ends up at [newIndex] (its final
  /// position, as ReorderableListView.onReorderItem reports it). The new
  /// order shows immediately and is saved in the background; if saving
  /// fails the old order comes back.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final save = saveOrder;
    final previous = state.songs;
    if (save == null || oldIndex < 0 || oldIndex >= previous.length) return;
    newIndex = newIndex.clamp(0, previous.length - 1);
    if (newIndex == oldIndex) return;

    final reordered = [...previous];
    reordered.insert(newIndex, reordered.removeAt(oldIndex));
    emit(
      SongListState(
        status: LoadStatus.ready,
        songs: reordered,
        reorderFailures: state.reorderFailures,
      ),
    );

    final result = await save(reordered);
    if (isClosed) return;
    if (result.isLeft()) {
      emit(
        SongListState(
          status: LoadStatus.ready,
          songs: previous,
          reorderFailures: state.reorderFailures + 1,
        ),
      );
    }
  }
}
