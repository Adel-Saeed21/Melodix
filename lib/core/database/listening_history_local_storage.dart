import 'dart:async';

import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/collections/song_history_collection.dart';

/// Every saved song (whatever the music filters show) and the history of
/// songs that left the library.
typedef ListeningHistoryRows = ({
  List<SongCollection> songs,
  List<SongHistoryCollection> removed,
});

/// Reads the listening history for the stats, unfiltered: the music
/// filters change what the library shows, never what was listened to.
abstract interface class ListeningHistoryLocalStorage {
  /// The history now, and again after each change to either.
  Stream<ListeningHistoryRows> watch();
}

class ListeningHistoryLocalStorageImpl implements ListeningHistoryLocalStorage {
  const ListeningHistoryLocalStorageImpl(this._isar);

  final Isar _isar;

  Future<ListeningHistoryRows> _read() async => (
    songs: await _isar.songCollections.where().findAll(),
    removed: await _isar.songHistoryCollections.where().findAll(),
  );

  @override
  Stream<ListeningHistoryRows> watch() {
    late final StreamController<ListeningHistoryRows> out;
    final subscriptions = <StreamSubscription<void>>[];
    var reading = false;
    var again = false;

    // One read at a time; changes during a read cause one more read.
    Future<void> read() async {
      if (reading) {
        again = true;
        return;
      }
      reading = true;
      try {
        do {
          again = false;
          final rows = await _read();
          if (out.isClosed) return;
          out.add(rows);
        } while (again);
      } catch (e, stack) {
        if (!out.isClosed) out.addError(e, stack);
      } finally {
        reading = false;
      }
    }

    out = StreamController<ListeningHistoryRows>(
      onListen: () {
        subscriptions
          ..add(_isar.songCollections.watchLazy().listen((_) => read()))
          ..add(_isar.songHistoryCollections.watchLazy().listen((_) => read()));
        unawaited(read());
      },
      onCancel: () async {
        for (final s in subscriptions) {
          await s.cancel();
        }
      },
    );
    return out.stream;
  }
}
