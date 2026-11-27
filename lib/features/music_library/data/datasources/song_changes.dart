import 'dart:async';

import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/features/music_library/data/datasources/song_library_update.dart';

/// What each committed write to the songs changed, turned into
/// [SongLibraryUpdate]s for `MusicLocalStorage.watchLibrary`: the full list
/// after bulk changes, only the affected songs after single-song edits,
/// always in the order the writes were made.
///
/// Every write to the songs goes through the storage, which reports it
/// here, so the updates are complete.
class SongChanges {
  final StreamController<_LibraryChange> _changes = StreamController.broadcast(
    sync: true,
  );

  /// Songs were added, removed or changed in bulk: re-read the library.
  void reload() => _changes.add(const _Reload());

  /// These rows changed in place.
  void changed(List<SongCollection> songs) => _changes.add(_Changed(songs));

  /// These songs left the visible library.
  void removed(Set<int> ids) => _changes.add(_Removed(ids));

  /// The library as a series of updates; [readAll] reads the whole visible
  /// library (sorted).
  Stream<SongLibraryUpdate> watch(
    Future<List<SongCollection>> Function() readAll,
  ) {
    late final StreamController<SongLibraryUpdate> out;
    StreamSubscription<_LibraryChange>? changes;
    // Steps run one after another, so updates keep the order of the writes
    // (a full reload is never overtaken by a later single-song change).
    var queue = Future<void>.value();
    var reloadsQueued = 0;

    void enqueue(Future<SongLibraryUpdate?> Function() step) {
      queue = queue.then((_) async {
        if (out.isClosed) return;
        try {
          final update = await step();
          if (update != null && !out.isClosed) out.add(update);
        } catch (e, stack) {
          if (!out.isClosed) out.addError(e, stack);
        }
      });
    }

    void reload() {
      reloadsQueued++;
      enqueue(() async {
        // A later reload is queued: it reads newer data, skip this one.
        if (--reloadsQueued > 0) return null;
        return SongLibraryLoaded(await readAll());
      });
    }

    out = StreamController<SongLibraryUpdate>(
      onListen: () {
        reload(); // the current library first
        changes = _changes.stream.listen(
          (change) => switch (change) {
            _Reload() => reload(),
            _Changed(:final songs) => enqueue(
              () async => SongLibrarySongsChanged(songs),
            ),
            _Removed(:final ids) => enqueue(
              () async => SongLibrarySongsRemoved(ids),
            ),
          },
        );
      },
      onCancel: () => changes?.cancel(),
    );
    return out.stream;
  }
}

sealed class _LibraryChange {
  const _LibraryChange();
}

/// Songs were added, removed or changed in bulk: re-read the library.
final class _Reload extends _LibraryChange {
  const _Reload();
}

/// These rows changed in place.
final class _Changed extends _LibraryChange {
  const _Changed(this.songs);

  final List<SongCollection> songs;
}

/// These songs left the visible library.
final class _Removed extends _LibraryChange {
  const _Removed(this.ids);

  final Set<int> ids;
}
