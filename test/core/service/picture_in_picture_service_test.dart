import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/service/picture_in_picture_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('melodix/pip');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('tells Android when to shrink, and in what shape', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final service = PictureInPictureServiceImpl(isAndroid: true);

    await service.setAutoEnter(enabled: true, width: 1280, height: 720);

    expect(calls.single.method, 'setAutoEnter');
    expect(calls.single.arguments, {
      'enabled': true,
      'playing': true,
      'width': 1280,
      'height': 720,
    });
  });

  test('reports going into the window and back', () async {
    final service = PictureInPictureServiceImpl(isAndroid: true);
    final changes = <bool>[];
    final sub = service.modeChanges.listen(changes.add);

    for (final inPip in [true, false]) {
      await messenger.handlePlatformMessage(
        'melodix/pip',
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('pipChanged', inPip),
        ),
        (_) {},
      );
    }
    await pumpEventQueue();
    await sub.cancel();
    expect(changes, [true, false]);
  });

  test('a platform without it: unsupported, and calls do nothing', () async {
    var called = false;
    messenger.setMockMethodCallHandler(channel, (_) async => called = true);
    final service = PictureInPictureServiceImpl(isAndroid: false);

    expect(await service.isSupported(), isFalse);
    await service.setAutoEnter(enabled: true, width: 16, height: 9);
    expect(called, isFalse);
  });

  test('a failing platform never breaks the video', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'boom'),
    );
    final service = PictureInPictureServiceImpl(isAndroid: true);

    expect(await service.isSupported(), isFalse);
    await service.setAutoEnter(enabled: true, width: 16, height: 9);
  });
}
