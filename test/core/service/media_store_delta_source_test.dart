import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/features/music_library/data/datasources/audio_library_delta_source.dart';

/// The Dart side of the "melodix/media_store" channel: device errors must
/// become typed exceptions, never empty or null results.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('melodix/media_store');
  const source = MediaStoreDeltaSource(isAndroid: true);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Object? Function(MethodCall call) handler) => messenger
      .setMockMethodCallHandler(channel, (call) async => handler(call));

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  const checkpoint = {
    'version': 'v1',
    'generations': {'external_primary': 5},
    'count': 1,
  };

  test('permission_denied → MediaPermissionException', () async {
    answer((_) => throw PlatformException(code: 'permission_denied'));

    await expectLater(
      source.currentCheckpoint(),
      throwsA(isA<MediaPermissionException>()),
    );
    await expectLater(
      source.changesSince({'external_primary': 1}),
      throwsA(isA<MediaPermissionException>()),
    );
    await expectLater(
      source.fullScan(),
      throwsA(isA<MediaPermissionException>()),
    );
  });

  test('query_failed → MediaQueryException (not null / empty)', () async {
    answer((_) => throw PlatformException(code: 'query_failed'));

    await expectLater(
      source.currentCheckpoint(),
      throwsA(isA<MediaQueryException>()),
    );
    await expectLater(
      source.changesSince(const {}),
      throwsA(isA<MediaQueryException>()),
    );
    await expectLater(source.fullScan(), throwsA(isA<MediaQueryException>()));
  });

  test('missing native handler → MediaQueryException', () async {
    // No mock handler: like an app build without the channel.
    await expectLater(
      source.changesSince(const {}),
      throwsA(isA<MediaQueryException>()),
    );
  });

  test('malformed or null answers are failures', () async {
    answer((call) => call.method == 'audioChangesSince' ? null : {'rows': 3});

    await expectLater(
      source.changesSince(const {}),
      throwsA(isA<MediaQueryException>()),
    );
    await expectLater(source.fullScan(), throwsA(isA<MediaQueryException>()));
  });

  test('a null checkpoint means "no generations" (Android 10)', () async {
    answer((_) => null);

    expect(await source.currentCheckpoint(), isNull);
  });

  test('parses a successful answer, including a real empty one', () async {
    answer(
      (call) => switch (call.method) {
        'audioCheckpoint' => checkpoint,
        'audioChangesSince' => {
          'checkpoint': {...checkpoint, 'count': 0},
          'changed': <Object?>[],
          'ids': <Object?>[],
        },
        _ => {
          'checkpoint': checkpoint,
          'rows': [
            {'id': 7, 'path': '/Music/a.mp3', 'title': 'A', 'isMusic': 1},
          ],
        },
      },
    );

    expect((await source.currentCheckpoint())!.audioCount, 1);
    final changes = await source.changesSince(const {});
    expect(changes.allIds, isEmpty);
    expect(changes.checkpoint.audioCount, 0);
    final scan = (await source.fullScan())!;
    expect(scan.records.single.id, 7);
    expect(scan.records.single.isMusic, isTrue);
  });

  test('other platforms: no generations and no native scan', () async {
    const ios = MediaStoreDeltaSource(isAndroid: false);

    expect(await ios.currentCheckpoint(), isNull);
    expect(await ios.fullScan(), isNull);
    await expectLater(
      ios.changesSince(const {}),
      throwsA(isA<MediaQueryException>()),
    );
  });
}
