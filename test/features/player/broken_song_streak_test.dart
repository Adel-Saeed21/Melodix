import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/player/data/session/broken_song_streak.dart';

void main() {
  test('skips up to 3 broken songs in a row, then stops', () {
    final streak = BrokenSongStreak();
    expect(
      [for (var i = 0; i < 4; i++) streak.skipAnother(hasNext: true)],
      [true, true, true, false],
    );
    // Stopping starts over.
    expect(streak.skipAnother(hasNext: true), isTrue);
  });

  test('a song that really plays ends the streak', () {
    final streak = BrokenSongStreak()
      ..skipAnother(hasNext: true)
      ..skipAnother(hasNext: true)
      ..reached(const Duration(seconds: 1)); // not yet
    expect(streak.skipAnother(hasNext: true), isTrue); // 3rd
    streak.reached(const Duration(seconds: 3));
    expect(
      [for (var i = 0; i < 4; i++) streak.skipAnother(hasNext: true)],
      [true, true, true, false],
    );
  });

  test('at the end of the queue it stops, and starts over', () {
    final streak = BrokenSongStreak()..skipAnother(hasNext: true);
    expect(streak.skipAnother(hasNext: false), isFalse);
    expect(
      [for (var i = 0; i < 4; i++) streak.skipAnother(hasNext: true)],
      [true, true, true, false],
    );
  });
}
