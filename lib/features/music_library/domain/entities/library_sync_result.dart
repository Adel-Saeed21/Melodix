import 'package:equatable/equatable.dart';

/// What a library sync changed.
class LibrarySyncResult extends Equatable {
  const LibrarySyncResult({
    required this.added,
    required this.updated,
    required this.removed,
    required this.total,
    required this.syncedAt,
  });

  final int added;
  final int updated;
  final int removed;

  /// Songs in the library after the sync.
  final int total;
  final DateTime syncedAt;

  bool get hasChanges => added > 0 || updated > 0 || removed > 0;

  @override
  List<Object?> get props => [added, updated, removed, total, syncedAt];
}
