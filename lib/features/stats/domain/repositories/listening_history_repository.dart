import 'package:melodix/features/stats/domain/entities/song_listening.dart';

abstract interface class ListeningHistoryRepository {
  /// Every song's listening (library and removed songs, unfiltered), now
  /// and whenever it changes.
  Stream<List<SongListening>> watchHistory();
}
