import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:melodix/features/music_library/domain/entities/song_sort_order.dart';
import 'package:melodix/features/music_library/presentation/logic/song_sort_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements Storage {}

void main() {
  late MockStorage storage;

  setUp(() {
    storage = MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  test('defaults to recently added', () {
    expect(SongSortCubit().state, SongSortOrder.recentlyAdded);
  });

  test('select changes the order', () {
    final cubit = SongSortCubit()..select(SongSortOrder.mostPlayed);
    expect(cubit.state, SongSortOrder.mostPlayed);
  });

  test('restores the saved order', () {
    when(() => storage.read(any())).thenReturn({'order': 'title'});
    expect(SongSortCubit().state, SongSortOrder.title);
  });

  test('round-trips through json and ignores unknown values', () {
    final cubit = SongSortCubit();
    for (final order in SongSortOrder.values) {
      expect(cubit.fromJson(cubit.toJson(order)!), order);
    }
    expect(cubit.fromJson({'order': 'nonsense'}), isNull);
  });
}
