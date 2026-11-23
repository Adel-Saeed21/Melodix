import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';

void main() {
  late PlaylistCollection playlist;

  setUp(() => playlist = PlaylistCollection.create('  Road trip  '));

  test('create trims the name and starts empty, not favorite', () {
    expect(playlist.name, 'Road trip');
    expect(playlist.songIds, isEmpty);
    expect(playlist.isFavorite, isFalse);
    expect(playlist.updatedAt, playlist.createdAt);
  });

  test('addSongs keeps order and skips duplicates', () {
    expect(playlist.addSongs([3, 1, 3]), 2);
    expect(playlist.addSongs([1, 2]), 1);
    expect(playlist.songIds, [3, 1, 2]);
    expect(playlist.songCount, 3);
  });

  test('removeSong removes only existing ids', () {
    playlist.addSongs([1, 2, 3]);
    expect(playlist.removeSong(2), isTrue);
    expect(playlist.removeSong(9), isFalse);
    expect(playlist.songIds, [1, 3]);
  });

  test('moveSong reorders and ignores out-of-range indexes', () {
    playlist.addSongs([1, 2, 3, 4]);
    playlist.moveSong(0, 2);
    expect(playlist.songIds, [2, 3, 1, 4]);
    playlist.moveSong(3, 0);
    expect(playlist.songIds, [4, 2, 3, 1]);
    playlist.moveSong(0, 10);
    expect(playlist.songIds, [4, 2, 3, 1]);
  });

  test('edits update updatedAt', () {
    final before = playlist.updatedAt;
    playlist.rename('New name');
    expect(playlist.name, 'New name');
    expect(playlist.updatedAt.isBefore(before), isFalse);
  });

  group('reorderVisible', () {
    test('reorders all songs when none are hidden', () {
      playlist.addSongs([1, 2, 3, 4]);

      expect(playlist.reorderVisible([3, 1, 4, 2]), isTrue);
      expect(playlist.songIds, [3, 1, 4, 2]);
    });

    test('hidden songs keep their exact positions', () {
      // 9 is hidden, so the screen only shows 1, 2, 3.
      playlist.addSongs([1, 9, 2, 3]);

      playlist.reorderVisible([3, 1, 2]);

      expect(playlist.songIds, [3, 9, 1, 2]);
    });

    test('ignores ids not in the playlist', () {
      playlist.addSongs([1, 2]);

      playlist.reorderVisible([2, 77, 1]);

      expect(playlist.songIds, [2, 1]);
    });

    test('no change or duplicate ids leave the order alone', () {
      playlist.addSongs([1, 2, 3]);

      expect(playlist.reorderVisible([1, 2, 3]), isFalse);
      expect(playlist.reorderVisible([2, 2, 1]), isFalse);
      expect(playlist.songIds, [1, 2, 3]);
    });
  });
}
