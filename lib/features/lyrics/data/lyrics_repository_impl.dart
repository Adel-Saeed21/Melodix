import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/lyrics/data/embedded_lyrics_reader.dart';
import 'package:melodix/features/lyrics/data/lrc_parser.dart';
import 'package:melodix/features/lyrics/data/lrclib_client.dart';
import 'package:melodix/features/lyrics/domain/entities/lyrics.dart';
import 'package:melodix/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

/// Lyrics from, in order: what was saved from online, an `.lrc` file
/// next to the song (where the phone lets the app read it), the song's
/// own tags. Online (LRCLIB) only when asked; what it finds is saved in
/// the app's files as `lyrics/<song id>.lrc`.
class LyricsRepositoryImpl implements LyricsRepository {
  LyricsRepositoryImpl({
    required this._savedDirectory,
    required this._online,
    this._embedded = const EmbeddedLyricsReader(),
    this._parser = const LrcParser(),
  });

  /// Where lyrics found online are kept.
  final Future<Directory> Function() _savedDirectory;
  final LrclibClient _online;
  final EmbeddedLyricsReader _embedded;
  final LrcParser _parser;

  @override
  Future<Lyrics?> local(Song song) async {
    final saved = await _readText(await _savedFile(song.id));
    if (saved != null) {
      final lyrics = _parser.parse(saved, LyricsSource.online);
      if (lyrics != null) return lyrics;
    }
    final beside = await _readText(File(_besidePath(song.path)));
    if (beside != null) {
      final lyrics = _parser.parse(beside, LyricsSource.file);
      if (lyrics != null) return lyrics;
    }
    if (song.path.isEmpty) return null;
    return _embedded.read(song.path);
  }

  @override
  Future<Either<Failure, Lyrics?>> searchOnline(Song song) async {
    final (title, artist) = searchTermsFor(song);
    try {
      final found = await _online.find(
        title: title,
        artist: artist,
        album: song.album == unknownAlbum ? null : song.album,
        duration: song.duration,
      );
      if (found == null) return const Right(null);
      // Synced if there are, otherwise the plain text.
      final text = found.synced ?? found.plain!;
      final lyrics = _parser.parse(text, LyricsSource.online);
      if (lyrics == null) return const Right(null);
      try {
        final file = await _savedFile(song.id);
        await file.parent.create(recursive: true);
        await file.writeAsString(text);
      } catch (_) {
        // Not saved: still shown now.
      }
      return Right(lyrics);
    } on LyricsLookupException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<void> forgetSaved(int songId) async {
    try {
      final file = await _savedFile(songId);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Title and artist to search with. A missing artist tag often hides in
  /// the title ("Artist - Title").
  static (String, String?) searchTermsFor(Song song) {
    final title = song.title.trim();
    if (song.artist != unknownArtist && song.artist.trim().isNotEmpty) {
      return (title, song.artist.trim());
    }
    final dash = title.indexOf(' - ');
    if (dash > 0) {
      return (
        title.substring(dash + 3).trim(),
        title.substring(0, dash).trim(),
      );
    }
    return (title, null);
  }

  Future<File> _savedFile(int songId) async =>
      File('${(await _savedDirectory()).path}/lyrics/$songId.lrc');

  /// `/music/Song.mp3` → `/music/Song.lrc`.
  static String _besidePath(String path) {
    final slash = path.lastIndexOf('/');
    final dot = path.lastIndexOf('.');
    return dot > slash ? '${path.substring(0, dot)}.lrc' : '$path.lrc';
  }

  static Future<String?> _readText(File file) async {
    try {
      if (!await file.exists()) return null;
      if (await file.length() > 512 * 1024) return null;
      // Any encoding: odd bytes shouldn't hide the whole file.
      return utf8.decode(await file.readAsBytes(), allowMalformed: true);
    } catch (_) {
      return null; // unreadable (scoped storage, encoding): no lyrics here
    }
  }
}
