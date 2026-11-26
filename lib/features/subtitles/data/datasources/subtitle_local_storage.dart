import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:melodix/core/utils/serial_runner.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_track.dart';
import 'package:path/path.dart' as p;

/// Subtitle files kept by the app (imported or downloaded), so they work
/// offline: one folder per video, with an `index.json` listing its tracks
/// and the user's choice.
///
/// Writes go one at a time, and files are written aside then renamed, so
/// an index is never half written.
class SubtitleLocalStorage {
  SubtitleLocalStorage({required this._root});

  /// The app's folder for subtitles (created when needed).
  final Future<Directory> Function() _root;
  final SerialRunner _writes = SerialRunner();

  static const String _indexName = 'index.json';

  /// The tracks saved for [videoId] (whose files still exist).
  Future<List<SubtitleTrack>> tracks(String videoId) async {
    final index = await _read(videoId);
    return [
      for (final track in index.tracks)
        if (await File(track.path).exists()) track,
    ];
  }

  Future<String?> selected(String videoId) async =>
      (await _read(videoId)).selected;

  Future<void> setSelected(String videoId, String? trackId) =>
      _writes.run(() async {
        final index = await _read(videoId);
        await _write(videoId, index.tracks, trackId);
      });

  /// A downloaded copy of OpenSubtitles file [remoteFileId], if kept.
  Future<SubtitleTrack?> downloaded(String videoId, int remoteFileId) async {
    for (final track in await tracks(videoId)) {
      if (track.remoteFileId == remoteFileId) return track;
    }
    return null;
  }

  /// Keeps [bytes] as a new track for [videoId] (replacing one with the
  /// same id).
  Future<SubtitleTrack> save({
    required String videoId,
    required String id,
    required String label,
    required SubtitleSource source,
    required String extension,
    required Uint8List bytes,
    String? language,
    int? remoteFileId,
  }) async {
    final saved = await _writes.run(() async {
      final dir = await _videoDir(videoId);
      final file = File(p.join(dir.path, '${_safe(id)}.$extension'));
      await _writeFile(file, bytes);
      final track = SubtitleTrack(
        id: id,
        videoId: videoId,
        label: label,
        source: source,
        path: file.path,
        language: language,
        remoteFileId: remoteFileId,
      );
      final index = await _read(videoId);
      await _write(videoId, [
        for (final t in index.tracks)
          if (t.id != id) t,
        track,
      ], index.selected);
      return track;
    });
    return saved!;
  }

  Future<Directory> _videoDir(String videoId) async =>
      Directory(p.join((await _root()).path, _safe(videoId)));

  Future<_Index> _read(String videoId) async {
    final dir = await _videoDir(videoId);
    final file = File(p.join(dir.path, _indexName));
    if (!await file.exists()) return const _Index([], null);
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) return const _Index([], null);
      final tracks = <SubtitleTrack>[];
      for (final raw in (json['tracks'] as List?) ?? const []) {
        final track = _trackFrom(videoId, dir, raw);
        if (track != null) tracks.add(track);
      }
      final selected = json['selected'];
      return _Index(tracks, selected is String ? selected : null);
    } on FormatException {
      return const _Index([], null); // a damaged index: start over
    } on FileSystemException {
      return const _Index([], null);
    }
  }

  Future<void> _write(
    String videoId,
    List<SubtitleTrack> tracks,
    String? selected,
  ) async {
    final dir = await _videoDir(videoId);
    final json = jsonEncode({
      'selected': selected,
      'tracks': [
        for (final t in tracks)
          {
            'id': t.id,
            'label': t.label,
            'source': t.source.name,
            'file': p.basename(t.path),
            'language': t.language,
            'remoteFileId': t.remoteFileId,
          },
      ],
    });
    await _writeFile(
      File(p.join(dir.path, _indexName)),
      Uint8List.fromList(utf8.encode(json)),
    );
  }

  /// A track from the index; its file is named relative to the video's
  /// folder (the app's folder can move between installs).
  static SubtitleTrack? _trackFrom(String videoId, Directory dir, Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final file = raw['file'];
    final label = raw['label'];
    if (id is! String || file is! String || label is! String) return null;
    final language = raw['language'];
    final remoteFileId = raw['remoteFileId'];
    return SubtitleTrack(
      id: id,
      videoId: videoId,
      label: label,
      source: SubtitleSource.values.firstWhere(
        (s) => s.name == raw['source'],
        orElse: () => SubtitleSource.imported,
      ),
      path: p.join(dir.path, p.basename(file)),
      language: language is String ? language : null,
      remoteFileId: remoteFileId is int ? remoteFileId : null,
    );
  }

  static Future<void> _writeFile(File file, Uint8List bytes) async {
    await file.parent.create(recursive: true);
    final partial = File('${file.path}.part');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(file.path);
  }

  /// A file name from any id (video ids may hold slashes).
  static String _safe(String id) =>
      id.replaceAll(RegExp('[^A-Za-z0-9_.-]'), '_');
}

class _Index {
  const _Index(this.tracks, this.selected);
  final List<SubtitleTrack> tracks;
  final String? selected;
}
