import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/database/video_local_storage.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/models/local_video.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:melodix/core/service/video_service.dart';
import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/features/video/data/repositories/video_errors.dart';
import 'package:melodix/features/video/data/repositories/video_media_repository_impl.dart';
import 'package:melodix/features/video/data/repositories/video_permission_repository_impl.dart';
import 'package:melodix/features/video/data/repositories/video_progress_repository_impl.dart';
import 'package:melodix/features/video/data/repositories/video_repository_impl.dart';
import 'package:melodix/features/video/data/repositories/video_sync_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockService extends Mock implements VideoService {}

class MockStorage extends Mock implements VideoLocalStorage {}

final _a = LocalVideo(
  id: 'a',
  title: 'A',
  duration: const Duration(minutes: 1),
  width: 1280,
  height: 720,
  createdAt: DateTime(2026),
);

void main() {
  late MockService service;
  late MockStorage storage;
  late VideoSyncRepositoryImpl sync;
  late VideoPermissionRepositoryImpl permission;
  late VideoMediaRepositoryImpl media;
  late VideoProgressRepositoryImpl progress;
  late VideoRepositoryImpl videos;

  setUpAll(() {
    registerFallbackValue(<LocalVideo>[]);
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    service = MockService();
    storage = MockStorage();
    sync = VideoSyncRepositoryImpl(service: service, storage: storage);
    permission = VideoPermissionRepositoryImpl(service);
    media = VideoMediaRepositoryImpl(service);
    progress = VideoProgressRepositoryImpl(storage);
    videos = VideoRepositoryImpl(storage: storage, service: service);
  });

  group('sync', () {
    // The device's fingerprint now, and the one saved at the last sync.
    const before = '2:old:100';
    const now = '3:new:200';

    setUp(() {
      when(() => service.checkpoint()).thenAnswer((_) async => now);
      when(() => storage.videoCheckpoint()).thenAnswer((_) async => before);
      when(() => storage.markVideosCheckedUnchanged()).thenAnswer((_) async {});
      when(() => storage.countVideos()).thenAnswer((_) async => 2);
      when(
        () => storage.syncVideos(
          any(),
          confirmedEmpty: any(named: 'confirmedEmpty'),
          checkpoint: any(named: 'checkpoint'),
        ),
      ).thenAnswer(
        (_) async =>
            const VideoSyncResult(added: 1, updated: 0, removed: 0, total: 1),
      );
    });

    test('nothing changed on the device: no scan at all', () async {
      when(() => service.checkpoint()).thenAnswer((_) async => before);

      final result = await sync.syncLibrary();

      final changes = result.getOrElse(() => throw StateError('failed'));
      expect(changes.hasChanges, isFalse);
      expect(changes.total, 2);
      verifyNever(() => service.scan());
      verifyNever(
        () => storage.syncVideos(
          any(),
          confirmedEmpty: any(named: 'confirmedEmpty'),
          checkpoint: any(named: 'checkpoint'),
        ),
      );
      verify(() => storage.markVideosCheckedUnchanged()).called(1);
    });

    test(
      'something changed: a full scan, saving the new fingerprint',
      () async {
        when(() => service.scan())
            .thenAnswer((_) async => VideoScan([_a], deviceCount: 1));

        await sync.syncLibrary();

        verify(() => service.scan()).called(1);
        verify(
          () =>
              storage.syncVideos([_a], confirmedEmpty: false, checkpoint: now),
        ).called(1);
      },
    );

    test('never synced before: a full scan', () async {
      when(() => storage.videoCheckpoint()).thenAnswer((_) async => null);
      when(() => service.checkpoint()).thenAnswer((_) async => before);
      when(() => service.scan())
          .thenAnswer((_) async => VideoScan([_a], deviceCount: 1));

      await sync.syncLibrary();
      verify(() => service.scan()).called(1);
    });

    test('Scan tapped (forced): a full scan even if nothing changed', () async {
      when(() => service.checkpoint()).thenAnswer((_) async => before);
      when(() => service.scan())
          .thenAnswer((_) async => VideoScan([_a], deviceCount: 1));

      await sync.syncLibrary(force: true);
      verify(() => service.scan()).called(1);
    });

    test('without access: a permission failure, and no dialog', () async {
      when(() => service.checkpoint())
          .thenThrow(const MediaPermissionException(permanentlyDenied: true));

      final result = await sync.syncLibrary();

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<PermissionFailure>());
      expect((failure! as PermissionFailure).permanentlyDenied, isTrue);
      verifyNever(() => service.requestPermission());
      verifyZeroInteractions(storage);
    });

    test("the check can't be made: a failure, library untouched", () async {
      when(() => service.checkpoint())
          .thenThrow(const MediaQueryException('busy'));

      expect((await sync.syncLibrary()).isLeft(), isTrue);
      verifyNever(() => service.scan());
      verifyZeroInteractions(storage);
    });

    test('a failed read leaves the library alone', () async {
      when(() => service.scan())
          .thenThrow(const MediaQueryException('Read 10 of 20'));

      final result = await sync.syncLibrary();

      expect(result.isLeft(), isTrue);
      verifyNever(
        () => storage.syncVideos(
          any(),
          confirmedEmpty: any(named: 'confirmedEmpty'),
          checkpoint: any(named: 'checkpoint'),
        ),
      );
    });

    test('only a device count of 0 may empty the library', () async {
      when(() => service.scan())
          .thenAnswer((_) async => VideoScan([_a], deviceCount: 1));
      await sync.syncLibrary();
      verify(
        () => storage.syncVideos([_a], confirmedEmpty: false, checkpoint: now),
      ).called(1);

      when(() => service.scan())
          .thenAnswer((_) async => const VideoScan([], deviceCount: 0));
      await sync.syncLibrary();
      verify(
        () => storage.syncVideos([], confirmedEmpty: true, checkpoint: now),
      ).called(1);
    });

    test('an unconfirmed empty scan is a failure, not "no videos"', () async {
      when(() => service.scan())
          .thenAnswer((_) async => const VideoScan([], deviceCount: 3));
      when(
        () => storage.syncVideos(
          any(),
          confirmedEmpty: any(named: 'confirmedEmpty'),
          checkpoint: any(named: 'checkpoint'),
        ),
      ).thenThrow(const MediaQueryException('kept'));

      final result = await sync.syncLibrary();

      expect(
        result,
        const Left<Failure, Never>(LibraryFailure(VideoErrors.sync)),
      );
    });

    test('syncs asked for at once share one scan', () async {
      final scan = Completer<VideoScan>();
      when(() => service.scan()).thenAnswer((_) => scan.future);

      final first = sync.syncLibrary();
      final second = sync.syncLibrary();
      await pumpEventQueue();
      scan.complete(VideoScan([_a], deviceCount: 1));
      await Future.wait([first, second]);

      verify(() => service.scan()).called(1);
    });
  });

  test('permission is checked without asking', () async {
    when(() => service.permissionStatus())
        .thenAnswer((_) async => MediaPermissionStatus.denied);

    expect(await permission.checkPermission(), LibraryPermission.denied);
    verifyNever(() => service.requestPermission());
  });

  group('thumbnails', () {
    test('read once, then served from memory synchronously', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      when(() => service.thumbnail('a', size: 200))
          .thenAnswer((_) async => bytes);

      expect(media.cachedThumbnail('a', size: 200), isNull);
      // Asked twice at once: one device read.
      final results = await Future.wait([
        Future.value(media.thumbnail('a', size: 200)),
        Future.value(media.thumbnail('a', size: 200)),
      ]);
      expect(results, [bytes, bytes]);
      verify(() => service.thumbnail('a', size: 200)).called(1);

      expect(media.cachedThumbnail('a', size: 200)?.bytes, bytes);
      expect(media.thumbnail('a', size: 200), same(bytes)); // no Future
      verifyNever(() => service.thumbnail('a', size: 200));
    });

    test('"no thumbnail" is remembered too', () async {
      when(() => service.thumbnail('a', size: 200))
          .thenAnswer((_) async => null);

      await media.thumbnail('a', size: 200);
      final cached = media.cachedThumbnail('a', size: 200);
      expect(cached, isNotNull);
      expect(cached!.bytes, isNull);
    });

    test('a failed read is not cached (retried later)', () async {
      when(() => service.thumbnail('a', size: 200))
          .thenThrow(StateError('no access yet'));

      expect(await media.thumbnail('a', size: 200), isNull);
      expect(media.cachedThumbnail('a', size: 200), isNull);
    });
  });

  test('a missing video has no playback URI (no crash)', () async {
    when(() => service.playbackUri('gone')).thenThrow(StateError('gone'));
    expect(await media.playbackUri('gone'), isNull);
  });

  group('progress', () {
    setUp(() {
      registerFallbackValue(Duration.zero);
      when(() => storage.savePlaybackPosition(any(), any()))
          .thenAnswer((_) async {});
    });

    test('one rule: within 10 s of the end counts as watched', () async {
      const length = Duration(minutes: 10);
      await progress.savePosition(
        'a',
        const Duration(minutes: 3),
        length: length,
      );
      verify(
        () => storage.savePlaybackPosition('a', const Duration(minutes: 3)),
      ).called(1);

      await progress.savePosition(
        'a',
        const Duration(minutes: 9, seconds: 52),
        length: length,
      );
      verify(() => storage.savePlaybackPosition('a', Duration.zero)).called(1);
    });

    test('a failed save never reaches the player', () async {
      when(() => storage.savePlaybackPosition(any(), any()))
          .thenThrow(StateError('disk full'));
      await progress.savePosition(
        'a',
        const Duration(minutes: 1),
        length: const Duration(minutes: 10),
      );
    });

    test('unreadable progress: just starts from the beginning', () async {
      when(() => storage.getProgress('a')).thenThrow(StateError('broken'));
      expect(await progress.progress('a'), isNull);
    });
  });

  group('favourites', () {
    test('a toggle that fails to save is a failure, not a crash', () async {
      when(() => storage.toggleFavorite('a')).thenThrow(StateError('locked'));
      expect(
        await videos.toggleFavorite('a'),
        const Left<Failure, bool>(LibraryFailure(VideoErrors.write)),
      );
    });

    test('returns the new value', () async {
      when(() => storage.toggleFavorite('a')).thenAnswer((_) async => true);
      expect(
        await videos.toggleFavorite('a'),
        const Right<Failure, bool>(true),
      );
    });
  });

  group('delete', () {
    setUp(() {
      when(() => storage.removeVideos(any())).thenAnswer((_) async {});
    });

    test('removes from the library only what the phone deleted', () async {
      // The user allowed one of the two in the system's dialog.
      when(() => service.delete(['a', 'b'])).thenAnswer((_) async => ['a']);

      expect((await videos.deleteVideos(['a', 'b'])).getOrElse(() => []), [
        'a',
      ]);
      verify(() => storage.removeVideos(['a'])).called(1);
    });

    test('the user said no: nothing deleted, library untouched', () async {
      when(() => service.delete(any())).thenAnswer((_) async => []);
      expect((await videos.deleteVideos(['a'])).getOrElse(() => ['x']), []);
      verifyNever(() => storage.removeVideos(any()));
    });

    test('a failed delete is a failure, and nothing is removed', () async {
      when(() => service.delete(any())).thenThrow(StateError('io'));
      expect(
        await videos.deleteVideos(['a']),
        const Left<Failure, List<String>>(LibraryFailure(VideoErrors.delete)),
      );
      verifyNever(() => storage.removeVideos(any()));
    });
  });

  test('favourite several at once', () async {
    when(() => storage.setFavorites(any(), favorite: any(named: 'favorite')))
        .thenAnswer((_) async {});
    expect(
      await videos.setFavorite(['a', 'b'], favorite: true),
      const Right<Failure, Unit>(unit),
    );
    verify(() => storage.setFavorites(['a', 'b'], favorite: true)).called(1);
  });
}
