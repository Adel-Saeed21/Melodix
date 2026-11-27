import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/features/music_library/data/datasources/music_service.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MockOnAudioQuery extends Mock implements OnAudioQuery {}

class MockPermissionService extends Mock implements PermissionHandlingService {}

SongModel _song(
  int id, {
  String title = 'Song',
  String? artist = 'Artist',
  bool isMusic = true,
  int duration = 180000,
}) {
  return SongModel({
    '_id': id,
    '_data': '/music/$id.mp3',
    '_uri': 'content://media/external/audio/media/$id',
    '_display_name_wo_ext': 'file_$id',
    '_size': 1000,
    'album': 'Album',
    'album_id': 7,
    'artist': artist,
    'duration': duration,
    'title': title,
    'is_music': isMusic,
    'date_added': 1767225600, // 2026-01-01T00:00:00Z
  });
}

void main() {
  late MockOnAudioQuery audioQuery;
  late MockPermissionService permissionService;
  late MusicServiceImpl service;

  setUp(() {
    audioQuery = MockOnAudioQuery();
    permissionService = MockPermissionService();
    service = MusicServiceImpl(
      audioQuery: audioQuery,
      permissionService: permissionService,
    );
  });

  void stubQuery(List<SongModel> songs) {
    when(
      () => audioQuery.querySongs(
        sortType: any(named: 'sortType'),
        orderType: any(named: 'orderType'),
        uriType: any(named: 'uriType'),
        ignoreCase: any(named: 'ignoreCase'),
      ),
    ).thenAnswer((_) async => songs);
  }

  test('throws when permission is denied and does not query', () async {
    when(() => permissionService.audioStatus())
        .thenAnswer((_) async => MediaPermissionStatus.denied);

    await expectLater(
      service.getAllSongs(),
      throwsA(
        isA<MediaPermissionException>().having(
          (e) => e.permanentlyDenied,
          'permanentlyDenied',
          false,
        ),
      ),
    );
    verifyNever(
      () => audioQuery.querySongs(
        sortType: any(named: 'sortType'),
        orderType: any(named: 'orderType'),
        uriType: any(named: 'uriType'),
        ignoreCase: any(named: 'ignoreCase'),
      ),
    );
  });

  test('reports permanently denied permission', () async {
    when(() => permissionService.audioStatus())
        .thenAnswer((_) async => MediaPermissionStatus.permanentlyDenied);

    await expectLater(
      service.getAllSongs(),
      throwsA(
        isA<MediaPermissionException>().having(
          (e) => e.permanentlyDenied,
          'permanentlyDenied',
          true,
        ),
      ),
    );
  });

  test('maps songs and skips non-music and empty files', () async {
    when(() => permissionService.audioStatus())
        .thenAnswer((_) async => MediaPermissionStatus.granted);
    stubQuery([
      _song(1, title: 'Hello', artist: '<unknown>'),
      _song(2, isMusic: false),
      _song(3, duration: 0),
    ]);

    final songs = await service.getAllSongs();

    expect(songs, hasLength(1));
    final song = songs.single;
    expect(song.id, 1);
    expect(song.title, 'Hello');
    expect(song.artist, 'Unknown artist');
    expect(song.duration, const Duration(minutes: 3));
    expect(song.path, '/music/1.mp3');
    expect(
      song.dateAdded,
      DateTime.fromMillisecondsSinceEpoch(1767225600 * 1000),
    );
  });

  test('never shows a permission dialog', () async {
    when(() => permissionService.audioStatus())
        .thenAnswer((_) async => MediaPermissionStatus.denied);

    await expectLater(
      service.getAllSongs(),
      throwsA(isA<MediaPermissionException>()),
    );
    verifyNever(() => permissionService.requestAudio());
  });

  test(
    'maps on_audio_query MissingPermissions to a permission error',
    () async {
      when(() => permissionService.audioStatus())
          .thenAnswer((_) async => MediaPermissionStatus.granted);
      when(
        () => audioQuery.querySongs(
          sortType: any(named: 'sortType'),
          orderType: any(named: 'orderType'),
          uriType: any(named: 'uriType'),
          ignoreCase: any(named: 'ignoreCase'),
        ),
      ).thenThrow(PlatformException(code: 'MissingPermissions'));

      await expectLater(
        service.getAllSongs(),
        throwsA(isA<MediaPermissionException>()),
      );
    },
  );

  test('artwork is not queried without permission (double reply)', () async {
    registerFallbackValue(ArtworkType.AUDIO);
    registerFallbackValue(ArtworkFormat.JPEG);
    when(() => permissionService.audioStatus())
        .thenAnswer((_) async => MediaPermissionStatus.denied);

    await expectLater(
      service.getArtwork(1),
      throwsA(isA<MediaPermissionException>()),
    );
    verifyNever(
      () => audioQuery.queryArtwork(
        any(),
        any(),
        format: any(named: 'format'),
        size: any(named: 'size'),
      ),
    );
  });
}
