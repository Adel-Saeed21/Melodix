import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Android's picture-in-picture: the app shrinks into a small window over
/// other apps when the user leaves it (Android 8+; elsewhere it's simply
/// unsupported and every call does nothing).
abstract interface class PictureInPictureService {
  Future<bool> isSupported();

  /// Whether leaving the app should shrink it into the window, and the
  /// window's shape. Only on while a video plays.
  Future<void> setAutoEnter({
    required bool enabled,
    required int width,
    required int height,
  });

  /// True when the app went into the window, false when it came back.
  Stream<bool> get modeChanges;
}

class PictureInPictureServiceImpl implements PictureInPictureService {
  PictureInPictureServiceImpl({MethodChannel? channel, bool? isAndroid})
    : _channel = channel ?? const MethodChannel('melodix/pip'),
      _android = isAndroid ?? Platform.isAndroid {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pipChanged') _changes.add(call.arguments == true);
    });
  }

  final MethodChannel _channel;
  final StreamController<bool> _changes = StreamController<bool>.broadcast();

  final bool _android;

  @override
  Stream<bool> get modeChanges => _changes.stream;

  @override
  Future<bool> isSupported() async {
    if (!_android) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> setAutoEnter({
    required bool enabled,
    required int width,
    required int height,
  }) async {
    if (!_android) return;
    try {
      await _channel.invokeMethod<void>('setAutoEnter', {
        'enabled': enabled,
        'width': width,
        'height': height,
      });
    } on PlatformException {
      // Best effort: without the window, the video just pauses as before.
    } on MissingPluginException {
      // Same.
    }
  }
}
