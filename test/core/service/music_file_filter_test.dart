import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/service/music_file_filter.dart';

bool isMusic(
  String path, {
  int durationMs = 200000,
  bool? music = true,
  bool? alarm,
  bool? notification,
  bool? ringtone,
  bool? podcast,
  bool? audiobook,
}) => MusicFileFilter.isMusic(
  path: path,
  durationMs: durationMs,
  isMusic: music,
  isAlarm: alarm,
  isNotification: notification,
  isRingtone: ringtone,
  isPodcast: podcast,
  isAudioBook: audiobook,
);

void main() {
  test('keeps normal songs', () {
    expect(isMusic('/storage/emulated/0/Music/Artist/song.mp3'), isTrue);
    expect(isMusic('/storage/emulated/0/Download/track.flac'), isTrue);
    expect(isMusic('/storage/emulated/0/Music/Album/01 - intro.m4a'), isTrue);
  });

  test('a missing "is music" flag is not treated as no', () {
    expect(isMusic('/storage/emulated/0/Music/a.mp3', music: null), isTrue);
  });

  test('drops files the device marks as non-music or system sounds', () {
    const path = '/storage/emulated/0/Music/a.mp3';
    expect(isMusic(path, music: false), isFalse);
    expect(isMusic(path, alarm: true), isFalse);
    expect(isMusic(path, notification: true), isFalse);
    expect(isMusic(path, ringtone: true), isFalse);
    expect(isMusic(path, podcast: true), isFalse);
    expect(isMusic(path, audiobook: true), isFalse);
  });

  test('drops recordings by folder, whatever the casing or spacing', () {
    for (final path in [
      '/storage/emulated/0/Recordings/Voice 001.m4a',
      '/storage/emulated/0/Recordings/Call/John.m4a',
      '/storage/emulated/0/MIUI/sound_recorder/rec.mp3',
      '/storage/emulated/0/Voice Recorder/memo.m4a',
      '/storage/emulated/0/Call recordings/2026-01-01.mp3',
      '/storage/emulated/0/CallRecordings/x.mp3',
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/'
          'WhatsApp Voice Notes/202601/PTT-001.opus',
      '/storage/emulated/0/Ringtones/tone.mp3',
      '/storage/emulated/0/Notifications/ding.ogg',
      '/storage/emulated/0/Podcasts/episode1.mp3',
    ]) {
      expect(isMusic(path), isFalse, reason: path);
    }
  });

  test('only folders count: a song named "recording" stays', () {
    expect(isMusic('/storage/emulated/0/Music/Recording.mp3'), isTrue);
    expect(isMusic('/storage/emulated/0/Music/Call Me Maybe.mp3'), isTrue);
  });

  test('drops voice recorder formats', () {
    expect(isMusic('/storage/emulated/0/Music/memo.amr'), isFalse);
    expect(isMusic('/storage/emulated/0/Music/clip.3gp'), isFalse);
    expect(isMusic('/storage/emulated/0/Music/x.AWB'), isFalse);
  });

  test('drops anything shorter than 30 seconds', () {
    const path = '/storage/emulated/0/Music/a.mp3';
    expect(isMusic(path, durationMs: 29999), isFalse);
    expect(isMusic(path, durationMs: 30000), isTrue);
    expect(MusicFileFilter.isMusic(path: path, durationMs: null), isFalse);
  });
}
