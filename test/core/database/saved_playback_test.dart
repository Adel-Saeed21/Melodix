import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/database/collections/playback_state_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/playback_state_local_storage.dart';

SongCollection _song(int id) => SongCollection()
  ..id = id
  ..title = 'Song $id'
  ..artist = 'Artist'
  ..album = 'Album'
  ..durationMs = 200000
  ..path = '/music/$id.mp3'
  ..sizeBytes = 1
  ..addedAt = DateTime(2026);

PlaybackStateCollection _state({
  required List<int> queue,
  required int index,
  int positionMs = 42000,
}) => PlaybackStateCollection()
  ..queueSongIds = queue
  ..originalQueueSongIds = queue
  ..currentIndex = index
  ..positionMs = positionMs
  ..shuffle = true
  ..repeatMode = PlayerRepeatMode.all
  ..speed = 1.25
  ..source = PlaybackSource.playlist
  ..sourceId = 9
  ..updatedAt = DateTime(2026);

Map<int, SongCollection> _library(List<int> ids) => {
  for (final id in ids) id: _song(id),
};

void main() {
  test('restores queue, index, position and settings unchanged', () {
    final saved = SavedPlayback.resolve(
      _state(queue: [1, 2, 3], index: 1),
      _library([1, 2, 3]),
    )!;

    expect(saved.queue.map((s) => s.id), [1, 2, 3]);
    expect(saved.currentIndex, 1);
    expect(saved.currentSong.id, 2);
    expect(saved.position, const Duration(seconds: 42));
    expect(saved.shuffle, isTrue);
    expect(saved.repeatMode, PlayerRepeatMode.all);
    expect(saved.speed, 1.25);
    expect(saved.source, PlaybackSource.playlist);
    expect(saved.sourceId, 9);
  });

  test('keeps the current song when earlier songs were deleted', () {
    final saved = SavedPlayback.resolve(
      _state(queue: [1, 2, 3, 4], index: 2),
      _library([2, 3, 4]),
    )!;

    expect(saved.currentSong.id, 3);
    expect(saved.currentIndex, 1);
    expect(saved.position, const Duration(seconds: 42));
  });

  test('moves to the next song from the start if the current one is gone', () {
    final saved = SavedPlayback.resolve(
      _state(queue: [1, 2, 3], index: 1),
      _library([1, 3]),
    )!;

    expect(saved.currentSong.id, 3);
    expect(saved.position, Duration.zero);
  });

  test(
    'falls back to the last song if the current and later ones are gone',
    () {
      final saved = SavedPlayback.resolve(
        _state(queue: [1, 2, 3], index: 2),
        _library([1, 2]),
      )!;

      expect(saved.currentSong.id, 2);
      expect(saved.position, Duration.zero);
    },
  );

  test('returns null when no saved song exists anymore', () {
    expect(
      SavedPlayback.resolve(_state(queue: [1, 2], index: 0), _library([])),
      isNull,
    );
  });
}
