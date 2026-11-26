import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SongSelectionState extends Equatable {
  const SongSelectionState({this.active = false, this.ids = const {}});

  /// Selection mode is on (rows show checkboxes, the action bar is shown).
  final bool active;
  final Set<int> ids;

  bool isSelected(int songId) => ids.contains(songId);

  @override
  List<Object?> get props => [active, ids];
}

/// Multi-select state for a list of songs.
class SongSelectionCubit extends Cubit<SongSelectionState> {
  SongSelectionCubit() : super(const SongSelectionState());

  /// Enters selection mode, optionally with [songId] already selected (e.g.
  /// from a long-press).
  void start([int? songId]) =>
      emit(SongSelectionState(active: true, ids: {?songId, ...state.ids}));

  void toggle(int songId) {
    final ids = {...state.ids};
    if (!ids.remove(songId)) ids.add(songId);
    emit(SongSelectionState(active: true, ids: ids));
  }

  void selectAll(Iterable<int> songIds) =>
      emit(SongSelectionState(active: true, ids: songIds.toSet()));

  void deselectAll() => emit(const SongSelectionState(active: true));

  /// Leaves selection mode and clears the selection.
  void exit() => emit(const SongSelectionState());
}
