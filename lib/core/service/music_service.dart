import 'dart:io';
import 'dart:typed_data';

import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/core/models/local_song.dart';
import 'package:melodix/core/service/music_file_filter.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:photo_manager/photo_manager.dart';

/// Reads the music stored on the device.
abstract interface class MusicService {
  /// All songs on the device, sorted by title. Requests permission if needed.
  ///
  /// Throws [MediaPermissionException] if access is denied.
  Future<List<LocalSong>> getAllSongs();

  /// Embedded artwork for [songId], or null if the song has none.
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

  static const String _unknown = '<unknown>';

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
    final permission = await _permissionService.requestAudio();
    if (!permission.isGranted) {
      throw MediaPermissionException(
        permanentlyDenied:
            permission == MediaPermissionStatus.permanentlyDenied,
      );
    }

    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    return songs
        // Music only: no recordings, voice notes or system sounds.
        .where(
          (s) => MusicFileFilter.isMusic(
            path: s.data,
            durationMs: s.duration,
            isMusic: s.isMusic,
            isAlarm: s.isAlarm,
            isNotification: s.isNotification,
            isRingtone: s.isRingtone,
            isPodcast: s.isPodcast,
            isAudioBook: s.isAudioBook,
          ),
        )
        .map(_toLocalSong)
        .toList(growable: false);
  }

  @override
  Future<Uint8List?> getArtwork(int songId, {int size = 200}) {
    return _audioQuery.queryArtwork(
      songId,
      ArtworkType.AUDIO,
      format: ArtworkFormat.JPEG,
      size: size,
    );
  }

  static LocalSong _toLocalSong(SongModel s) {
    String clean(String? value, String fallback) =>
        (value == null || value.isEmpty || value == _unknown)
        ? fallback
        : value;

    return LocalSong(
      id: s.id,
      title: clean(s.title, s.displayNameWOExt),
      artist: clean(s.artist, 'Unknown artist'),
      album: clean(s.album, 'Unknown album'),
      albumId: s.albumId,
      duration: Duration(milliseconds: s.duration ?? 0),
      path: s.data,
      uri: s.uri,
      size: s.size,
      dateAdded: s.dateAdded == null || s.dateAdded! <= 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(s.dateAdded! * 1000),
    );
  }
}
