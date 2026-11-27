import 'package:melodix/core/database/listening_history_local_storage.dart';
import 'package:melodix/features/stats/domain/entities/song_listening.dart';
import 'package:melodix/features/stats/domain/repositories/listening_history_repository.dart';

class ListeningHistoryRepositoryImpl implements ListeningHistoryRepository {
  const ListeningHistoryRepositoryImpl(this._storage);

  final ListeningHistoryLocalStorage _storage;

  @override
  Stream<List<SongListening>> watchHistory() =>
      _storage.watch().map(_toEntities);

  static List<SongListening> _toEntities(ListeningHistoryRows rows) => [
    for (final s in rows.songs)
      SongListening(
        id: s.id,
        title: s.title,
        artist: s.artist,
        playCount: s.playCount,
        listened: Duration(milliseconds: s.listenedOrEstimateMs),
        isFavorite: s.isFavorite,
      ),
    for (final h in rows.removed)
      SongListening(
        id: h.id,
        title: h.title,
        artist: h.artist,
        playCount: h.playCount,
        listened: Duration(milliseconds: h.listenedMs),
        inLibrary: false,
      ),
  ];
}
