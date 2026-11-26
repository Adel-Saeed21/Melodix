import 'dart:io';
import 'dart:typed_data';

import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/repositories/artwork_repository.dart';
import 'package:path/path.dart' as p;

/// Song covers as image files, for the media notification and the lock
/// screen (the system loads artwork from a file, not from memory).
///
/// Covers come from the same [ArtworkRepository] as the app's own screens,
/// with the Melodix finish added ([_brand]: a green wash and the Melodix
/// badge), so the system player looks like Melodix. Songs without one get
/// the branded [_fallbackCover] (rendered once, then reused). Files are kept for the
/// last [keep] songs played, so going back and forth costs nothing; older
/// ones are deleted.
class NowPlayingArtworkFiles {
  NowPlayingArtworkFiles({
    required this._artwork,
    required this._directory,
    required this._fallbackCover,
    this._brand,
    this.size = 512,
    this.keep = 30,
  });

  final ArtworkRepository _artwork;
  final Future<Directory> Function() _directory;

  /// PNG bytes of the cover for songs without one.
  final Future<Uint8List> Function() _fallbackCover;

  /// Adds the Melodix finish to a cover (PNG out). Null: covers as they
  /// are. If it fails for a cover, that cover is used as it is.
  final Future<Uint8List> Function(Uint8List cover)? _brand;

  /// Bump when the branded design changes (the system caches covers by
  /// file name, so a new design needs new names).
  static const String _brandVersion = 'm1';

  /// Cover size in pixels: sharp on a lock screen, small on disk.
  final int size;
  final int keep;

  /// Bump when the fallback's design changes: the system caches covers by
  /// file name, so a new design needs a new name.
  static const String _fallbackName = 'melodix_cover_v1.png';

  Directory? _dir;
  Future<Uri?>? _fallback;

  /// A file URI for [song]'s cover, or the branded fallback's if it has
  /// none. Null only if no file can be written (the notification then shows
  /// no cover; playback goes on).
  Future<Uri?> uriFor(Song song) => uriForKey(
    '${song.id}',
    () async => _artwork.getArtwork(song.id, size: size),
  );

  /// Like [uriFor], for anything else shown in the media controls (e.g. a
  /// video's thumbnail): [key] names the file, [load] gives the picture.
  Future<Uri?> uriForKey(String key, Future<Uint8List?> Function() load) async {
    try {
      final dir = _dir ??= await _directory();
      final file = File(
        p.join(
          dir.path,
          _brand == null
              ? '${_safe(key)}.jpg'
              : '${_safe(key)}_$_brandVersion.png',
        ),
      );
      if (await file.exists()) return file.uri;

      final Uint8List? bytes;
      try {
        bytes = await load();
      } on Object {
        return await _fallbackUri(dir);
      }
      if (bytes == null || bytes.isEmpty) return await _fallbackUri(dir);
      await _write(file, await _branded(bytes));
      await _prune(dir);
      return file.uri;
    } on FileSystemException {
      return null;
    }
  }

  Future<Uint8List> _branded(Uint8List cover) async {
    final brand = _brand;
    if (brand == null) return cover;
    try {
      return await brand(cover);
    } on Object {
      return cover; // not decodable as an image: shown as it is
    }
  }

  /// A file name from any key (video ids may hold slashes).
  static String _safe(String key) =>
      key.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_');

  /// The fallback cover's file, rendered the first time it's needed.
  Future<Uri?> _fallbackUri(Directory dir) => _fallback ??= () async {
    try {
      final file = File(p.join(dir.path, _fallbackName));
      if (!await file.exists()) await _write(file, await _fallbackCover());
      return file.uri;
    } on Object {
      _fallback = null; // try again next time
      return null;
    }
  }();

  /// Written aside, then renamed: the system never reads half a file.
  static Future<void> _write(File file, Uint8List bytes) async {
    await file.parent.create(recursive: true);
    final partial = File('${file.path}.part');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(file.path);
  }

  /// Deletes all but the [keep] most recently written covers (older
  /// designs' files included; never the fallback).
  Future<void> _prune(Directory dir) async {
    final files = [
      await for (final entity in dir.list())
        if (entity is File &&
            (entity.path.endsWith('.jpg') || entity.path.endsWith('.png')) &&
            p.basename(entity.path) != _fallbackName)
          entity,
    ];
    if (files.length <= keep) return;
    final byAge = [
      for (final file in files) (file: file, time: await file.lastModified()),
    ]..sort((a, b) => b.time.compareTo(a.time));
    for (final old in byAge.skip(keep)) {
      try {
        await old.file.delete();
      } on FileSystemException {
        // Already gone: fine.
      }
    }
  }
}
