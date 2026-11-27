import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/features/player/domain/repositories/play_recorder.dart';

/// Records plays in the music library's storage (play count and the
/// recently played list, in one transaction) and the time listened.
class StoragePlayRecorder implements PlayRecorder {
  const StoragePlayRecorder(this._storage);

  final MusicLocalStorage _storage;

  @override
  Future<void> recordPlay(int songId) => _storage.recordPlay(songId);

  @override
  Future<void> addListening(int songId, Duration listened) =>
      _storage.addListening(songId, listened);
}
