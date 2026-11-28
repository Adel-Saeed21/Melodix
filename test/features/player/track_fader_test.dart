import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/player/data/session/track_fader.dart';

void main() {
  late List<double> sent;
  late TrackFader fader;

  Duration s(num seconds) => Duration(milliseconds: (seconds * 1000).round());
  double last() => sent.last;

  setUp(() {
    sent = [];
    fader = TrackFader((volume) async => sent.add(volume));
  });

  Future<void> at(num position, {num? of = 200}) =>
      fader.update(position: s(position), duration: of == null ? null : s(of));

  test('off: positions never change the volume', () async {
    await at(199.5);
    await at(0.1);
    expect(sent, isEmpty);
  });

  test('fades out over the last seconds of a song', () async {
    await fader.setLength(s(4));
    await at(100);
    expect(last(), 1);
    await at(197);
    expect(last(), closeTo(0.75, 0.01));
    await at(199);
    expect(last(), closeTo(0.25, 0.01));
  });

  test('after a fade-out, the next song fades in', () async {
    await fader.setLength(s(4));
    await at(199.6);
    // The next song (the player may still report the old length).
    await at(0);
    expect(last(), 0);
    await at(1, of: 180);
    expect(last(), closeTo(0.25, 0.01));
    await at(3, of: 180);
    expect(last(), closeTo(0.75, 0.01));
    await at(5, of: 180);
    expect(last(), 1);
  });

  test('a song started by hand plays at full volume at once', () async {
    await fader.setLength(s(4));
    await at(60);
    await at(0.5, of: 180);
    expect(last(), 1);
  });

  test('seeking out of a fade brings the volume straight back', () async {
    await fader.setLength(s(4));
    await at(198);
    expect(last(), closeTo(0.5, 0.01));
    await at(50);
    expect(last(), 1);
  });

  test('a short song fades over at most a quarter of it', () async {
    await fader.setLength(s(12));
    await at(10, of: 20); // fades take 5s here
    expect(last(), 1);
    await at(17.5, of: 20);
    expect(last(), closeTo(0.5, 0.01));
  });

  test(
    'multiplies the app volume (sleep timer) instead of replacing it',
    () async {
      await fader.setLength(s(4));
      await fader.setVolume(0.5);
      expect(last(), 0.5);
      await at(198);
      expect(last(), closeTo(0.25, 0.01));
      await fader.setVolume(1);
      expect(last(), closeTo(0.5, 0.01));
    },
  );

  test('turning it off mid-fade restores full volume', () async {
    await fader.setLength(s(4));
    await at(199);
    await fader.setLength(Duration.zero);
    expect(last(), 1);
  });
}
