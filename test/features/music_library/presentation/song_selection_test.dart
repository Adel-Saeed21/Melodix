import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/music_library/presentation/logic/song_selection_cubit.dart';

void main() {
  test('starts inactive with nothing selected', () {
    final cubit = SongSelectionCubit();
    expect(cubit.state.active, isFalse);
    expect(cubit.state.ids, isEmpty);
  });

  test('start enters selection, optionally with a song', () {
    final cubit = SongSelectionCubit()..start();
    expect(cubit.state.active, isTrue);
    expect(cubit.state.ids, isEmpty);

    cubit.start(5);
    expect(cubit.state.ids, {5});
  });

  test('toggle adds and removes, staying in selection mode', () {
    final cubit = SongSelectionCubit()
      ..start(1)
      ..toggle(2);
    expect(cubit.state.ids, {1, 2});

    cubit
      ..toggle(1)
      ..toggle(2);
    expect(cubit.state.ids, isEmpty);
    expect(cubit.state.active, isTrue);
  });

  test('select all, deselect all and exit', () {
    final cubit = SongSelectionCubit()..selectAll([1, 2, 3]);
    expect(cubit.state.ids, {1, 2, 3});

    cubit.deselectAll();
    expect(cubit.state.ids, isEmpty);
    expect(cubit.state.active, isTrue);

    cubit.exit();
    expect(cubit.state.active, isFalse);
  });
}
