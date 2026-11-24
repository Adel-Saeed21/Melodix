import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectionState<K> extends Equatable {
  const SelectionState({this.active = false, this.ids = const {}});

  /// Selection mode is on (rows show checks, the action bar is shown).
  final bool active;
  final Set<K> ids;

  bool isSelected(K id) => ids.contains(id);

  @override
  List<Object?> get props => [active, ids];
}

/// Multi-select state for a list (songs by id, videos by id…).
class SelectionCubit<K> extends Cubit<SelectionState<K>> {
  SelectionCubit() : super(SelectionState<K>());

  /// Enters selection mode, optionally with [id] already selected (e.g.
  /// from a long-press).
  void start([K? id]) =>
      emit(SelectionState(active: true, ids: {...state.ids, ?id}));

  void toggle(K id) {
    final ids = {...state.ids};
    if (!ids.remove(id)) ids.add(id);
    emit(SelectionState(active: true, ids: ids));
  }

  void selectAll(Iterable<K> ids) =>
      emit(SelectionState(active: true, ids: ids.toSet()));

  void deselectAll() => emit(SelectionState<K>(active: true));

  /// Leaves selection mode and clears the selection.
  void exit() => emit(SelectionState<K>());
}
