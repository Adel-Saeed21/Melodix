import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Android's picture-in-picture: the app shrinks into a small window over
/// other apps when the user leaves it (Android 8+; elsewhere it's simply
/// unsupported and every call does nothing).
abstract interface class PictureInPictureService {
  Future<bool> isSupported();

  /// Whether leaving the app should shrink it into the window, and the
  /// window's shape. Only on while a video plays. [playing] picks the
  /// window's middle button (pause while playing, else play).
  Future<void> setAutoEnter({
    required bool enabled,
    bool? playing,
    required int width,
    required int height,
  });

  /// True when the app went into the window, false when it came back.
  Stream<bool> get modeChanges;

  /// The window's own buttons, tapped: what the video should do.
  Stream<PictureInPictureAction> get actions;
}

/// The picture-in-picture window's buttons (back, play / pause, forward).
/// They're the app's own, so they control the video (not the music).
enum PictureInPictureAction { rewind, play, pause, forward }

class PictureInPictureServiceImpl implements PictureInPictureService {
  PictureInPictureServiceImpl({MethodChannel? channel, bool? isAndroid})
    : _channel = channel ?? const MethodChannel('melodix/pip'),
      _android = isAndroid ?? Platform.isAndroid {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'pipChanged':
          _changes.add(call.arguments == true);
        case 'pipAction':
          for (final action in PictureInPictureAction.values) {
            if (action.name == call.arguments) _actions.add(action);
          }
      }
    });
  }

  final MethodChannel _channel;
  final StreamController<bool> _changes = StreamController<bool>.broadcast();
  final StreamController<PictureInPictureAction> _actions =
      StreamController<PictureInPictureAction>.broadcast();

  final bool _android;

  @override
  Stream<bool> get modeChanges => _changes.stream;

  @override
  Stream<PictureInPictureAction> get actions => _actions.stream;

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
    bool? playing,
    required int width,
    required int height,
  }) async {
    if (!_android) return;
    try {
      await _channel.invokeMethod<void>('setAutoEnter', {
        'enabled': enabled,
        'playing': playing ?? enabled,
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
