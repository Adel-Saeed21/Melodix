import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Which songs the library shows: none shorter than [minSeconds], none
/// from [excludedFolders] (or folders inside them).
///
/// Applied when the library is read, not when the phone is scanned, so
/// nothing is deleted: a folder turned back on returns with its plays,
/// favourites and playlist places.
class LibraryFilter extends Equatable {
  const LibraryFilter({this.minSeconds = 30, this.excludedFolders = const {}});

  /// The shortest-song choices. 30 s is what the scan already keeps.
  static const List<int> minSecondsChoices = [30, 60, 120, 180];

  static const defaults = LibraryFilter();

  final int minSeconds;

  /// Folder paths, without a trailing slash.
  final Set<String> excludedFolders;

  /// Shows everything the scan kept.
  bool get isDefault => this == defaults;

  bool keeps({required String path, required int durationMs}) {
    if (durationMs < minSeconds * 1000) return false;
    for (final folder in excludedFolders) {
      if (path.startsWith('$folder/')) return false;
    }
    return true;
  }

  /// The folder [path] is in.
  static String folderOf(String path) {
    final slash = path.lastIndexOf('/');
    return slash <= 0 ? '/' : path.substring(0, slash);
  }

  LibraryFilter copyWith({int? minSeconds, Set<String>? excludedFolders}) =>
      LibraryFilter(
        minSeconds: minSeconds ?? this.minSeconds,
        excludedFolders: excludedFolders ?? this.excludedFolders,
      );

  @override
  List<Object?> get props => [minSeconds, excludedFolders];
}

/// The library filter, saved across restarts.
class LibraryFilterCubit extends HydratedCubit<LibraryFilter> {
  LibraryFilterCubit() : super(LibraryFilter.defaults);

  void setMinSeconds(int seconds) {
    if (LibraryFilter.minSecondsChoices.contains(seconds)) {
      emit(state.copyWith(minSeconds: seconds));
    }
  }

  /// Shows ([included]) or hides the songs in [folder].
  void setFolder(String folder, {required bool included}) {
    final folders = {...state.excludedFolders};
    included ? folders.remove(folder) : folders.add(folder);
    emit(state.copyWith(excludedFolders: Set.unmodifiable(folders)));
  }

  @override
  LibraryFilter? fromJson(Map<String, dynamic> json) {
    final seconds = json['minSeconds'];
    final folders = json['excludedFolders'];
    return LibraryFilter(
      minSeconds: LibraryFilter.minSecondsChoices.contains(seconds)
          ? seconds as int
          : LibraryFilter.defaults.minSeconds,
      excludedFolders: folders is List
          ? Set.unmodifiable(folders.whereType<String>())
          : const {},
    );
  }

  @override
  Map<String, dynamic>? toJson(LibraryFilter state) => {
    'minSeconds': state.minSeconds,
    'excludedFolders': state.excludedFolders.toList(),
  };
}
