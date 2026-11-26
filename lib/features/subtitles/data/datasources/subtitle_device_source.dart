import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// A subtitle file on the device: its name and contents.
typedef DeviceSubtitleFile = ({String name, Uint8List bytes});

/// What the device itself offers for subtitles (Android; elsewhere it
/// offers nothing and every call answers "none"):
/// * where a video's file is, to find subtitle files next to it;
/// * the system file picker, to import one from anywhere (Downloads, a
///   USB stick, Drive...).
abstract interface class SubtitleDeviceSource {
  bool get canPick;

  /// The video file's path, when it can be read directly (null if not).
  Future<String?> videoPath(Uri playbackUri);

  /// SRT / VTT files next to [videoPath] whose names start like the
  /// video's ("Film.mkv" → "Film.srt", "Film.en.vtt"). Best effort: on
  /// Android 11+ the system may hide non-media files from apps.
  Future<List<File>> nearbySubtitles(String videoPath);

  /// The system's file picker; null if the user cancelled.
  Future<DeviceSubtitleFile?> pick();
}

class SubtitleDeviceSourceImpl implements SubtitleDeviceSource {
  SubtitleDeviceSourceImpl({MethodChannel? channel, bool? isAndroid})
    : _channel = channel ?? const MethodChannel('melodix/subtitles'),
      _android = isAndroid ?? Platform.isAndroid;

  final MethodChannel _channel;
  final bool _android;

  static const List<String> extensions = ['.srt', '.vtt'];

  @override
  bool get canPick => _android;

  @override
  Future<String?> videoPath(Uri playbackUri) async {
    if (playbackUri.scheme == 'file') return playbackUri.toFilePath();
    if (!_android || playbackUri.scheme != 'content') return null;
    try {
      return await _channel.invokeMethod<String>('videoPath', {
        'uri': playbackUri.toString(),
      });
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<List<File>> nearbySubtitles(String videoPath) async {
    final base = p.basenameWithoutExtension(videoPath).toLowerCase();
    final dir = Directory(p.dirname(videoPath));
    try {
      final found = <File>[];
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = p.basename(entity.path).toLowerCase();
        if (name.startsWith(base) && extensions.contains(p.extension(name))) {
          found.add(entity);
        }
      }
      found.sort((a, b) => a.path.compareTo(b.path));
      return found;
    } on FileSystemException {
      return const []; // not readable: nothing nearby
    }
  }

  @override
  Future<DeviceSubtitleFile?> pick() async {
    if (!_android) return null;
    final Map<Object?, Object?>? result;
    try {
      result = await _channel.invokeMethod<Map<Object?, Object?>>('pick');
    } on MissingPluginException {
      return null;
    }
    if (result == null) return null;
    final name = result['name'];
    final bytes = result['bytes'];
    if (name is! String || bytes is! Uint8List) return null;
    return (name: name, bytes: bytes);
  }
}
