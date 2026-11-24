import 'package:equatable/equatable.dart';

/// What a video library sync changed.
class VideoLibraryChanges extends Equatable {
  const VideoLibraryChanges({
    required this.added,
    required this.updated,
    required this.removed,
    required this.total,
  });

  final int added;
  final int updated;
  final int removed;

  /// Videos in the library after the sync.
  final int total;

  bool get hasChanges => added > 0 || updated > 0 || removed > 0;

  @override
  List<Object?> get props => [added, updated, removed, total];
}
