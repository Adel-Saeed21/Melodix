import 'dart:io';

import 'package:flutter/services.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/features/music_library/data/models/local_song.dart';
import 'package:melodix/features/music_library/data/datasources/local_song_builder.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:photo_manager/photo_manager.dart';

/// Reads the music stored on the device.
abstract interface class MusicService {
  /// All songs on the device, sorted by title. Never shows a permission
  /// dialog (callers request permission from the UI first).
  ///
  /// Throws [MediaPermissionException] if access is denied.
  Future<List<LocalSong>> getAllSongs();

  /// Embedded artwork for [songId], or null if the song has none.
  ///
  /// Throws [MediaPermissionException] if the app can't read music now.
  Future<Uint8List?> getArtwork(int songId, {int size = 200});

  /// Whether this platform lets the app delete song files (Android only).
  bool get canDeleteSongs;

  /// Deletes song files from the device. On Android 11+ the system asks the
  /// user to confirm. Returns the ids actually deleted (empty if the user
  /// declined).
  Future<List<int>> deleteSongs(List<int> songIds);
}

class MusicServiceImpl implements MusicService {
  MusicServiceImpl({
    required this._audioQuery,
    required this._permissionService,
  });

  final OnAudioQuery _audioQuery;
  final PermissionHandlingService _permissionService;

  @override
  bool get canDeleteSongs => Platform.isAndroid;

  @override
  Future<List<int>> deleteSongs(List<int> songIds) async {
    if (!canDeleteSongs || songIds.isEmpty) return const [];
    // Access is handled by PermissionHandlingService; photo_manager deletes
    // through MediaStore (system confirmation dialog on Android 11+).
    await PhotoManager.setIgnorePermissionCheck(true);
    final deleted = await PhotoManager.editor.deleteWithIds([
      for (final id in songIds) '$id',
    ]);
    return [for (final id in deleted) ?int.tryParse(id)];
  }

  @override
  Future<List<LocalSong>> getAllSongs() async {
    // Status only, no dialog: this runs during background syncs.
    final permission = await _permissionService.audioStatus();
    if (!permission.isGranted) {
      throw MediaPermissionException(
        permanentlyDenied:
            permission == MediaPermissionStatus.permanentlyDenied,
      );
    }

    final List<SongModel> songs;
    try {
      songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
    } on PlatformException catch (e) {
      throw _queryError(e);
    }

    // Music only: no recordings, voice notes or system sounds. Same rules
    // and mapping as the incremental scan (see buildMusicLocalSong).
    return [for (final s in songs) ?_toLocalSong(s)];
  }

  @override
  Future<Uint8List?> getArtwork(int songId, {int size = 200}) async {
    // on_audio_query answers twice when it lacks permission (an error, then
    // the result), which can crash the app: never call it without access.
    if (!await _canReadAudio()) {
      throw const MediaPermissionException(permanentlyDenied: false);
    }
    try {
      return await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: size,
      );
    } on PlatformException catch (e) {
      if (e.code == _missingPermissions) _audioAccess = null;
      throw _queryError(e);
    }
  }

  /// on_audio_query's error code when it has no read permission.
  static const String _missingPermissions = 'MissingPermissions';

  /// Recent answer to "can we read audio?", so scrolling a list of covers
  /// doesn't ask the system once per cover.
  ({bool granted, DateTime at})? _audioAccess;
  static const Duration _accessTtl = Duration(seconds: 5);

  Future<bool> _canReadAudio() async {
    final cached = _audioAccess;
    if (cached != null && DateTime.now().difference(cached.at) < _accessTtl) {
      return cached.granted;
    }
    final granted = (await _permissionService.audioStatus()).isGranted;
    _audioAccess = (granted: granted, at: DateTime.now());
    return granted;
  }

  static Exception _queryError(PlatformException e) =>
      e.code == _missingPermissions
      ? const MediaPermissionException(permanentlyDenied: false)
      : MediaQueryException('${e.code}: ${e.message}');

  static LocalSong? _toLocalSong(SongModel s) => buildMusicLocalSong(
    id: s.id,
    path: s.data,
    uri: s.uri,
    title: s.title,
    artist: s.artist,
    album: s.album,
    albumId: s.albumId,
    durationMs: s.duration,
    size: s.size,
    dateAddedSeconds: s.dateAdded,
    isMusic: s.isMusic,
    isAlarm: s.isAlarm,
    isNotification: s.isNotification,
    isRingtone: s.isRingtone,
    isPodcast: s.isPodcast,
    isAudioBook: s.isAudioBook,
  );
}
