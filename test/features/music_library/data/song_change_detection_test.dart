import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/database/collections/song_collection.dart';

import '../fixtures.dart';

void main() {
  test('identical scan data counts as unchanged', () {
    expect(songRow(1).hasSameScanData(songRow(1)), isTrue);
  });

  test('user data differences are not metadata changes', () {
    final favorite = songRow(1)
      ..isFavorite = true
      ..playCount = 3;
    expect(songRow(1).hasSameScanData(favorite), isTrue);
  });

  test('any changed metadata field counts as modified', () {
    final base = songRow(1);
    final variants = <SongCollection>[
      songRow(1, title: 'Renamed'),
      songRow(1, artist: 'Other'),
      songRow(1, album: 'Other'),
      songRow(1, albumId: 2),
      songRow(1, durationMs: 1),
      songRow(1, uri: 'content://x'),
      songRow(1)..path = '/moved.mp3',
      songRow(1)..sizeBytes = 1,
      songRow(1)..dateAdded = DateTime(2026, 1, 1),
    ];
    for (final changed in variants) {
      expect(base.hasSameScanData(changed), isFalse);
    }
  });
}
