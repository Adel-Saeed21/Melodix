import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:melodix/features/music_library/domain/entities/song_sort_order.dart';

/// The Songs tab's sort order, remembered across app launches.
class SongSortCubit extends HydratedCubit<SongSortOrder> {
  SongSortCubit() : super(SongSortOrder.recentlyAdded);

  void select(SongSortOrder order) => emit(order);

  @override
  SongSortOrder? fromJson(Map<String, dynamic> json) {
    final name = json['order'];
    for (final order in SongSortOrder.values) {
      if (order.name == name) return order;
    }
    return null; // unknown value: keep the default
  }

  @override
  Map<String, dynamic>? toJson(SongSortOrder state) => {'order': state.name};
}
