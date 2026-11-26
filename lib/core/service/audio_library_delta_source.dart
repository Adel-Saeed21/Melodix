import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/core/models/local_song.dart';
import 'package:melodix/core/service/local_song_builder.dart';

/// Where MediaStore's audio library stood at one moment: its database
/// version, the latest generation of each storage volume and the number of
/// audio rows. Android 11+ only.
class MediaStoreCheckpoint extends Equatable {
  const MediaStoreCheckpoint({
    required this.version,
    required this.generations,
    required this.audioCount,
  });

  /// Changes when MediaStore's database is rebuilt; generations from another
  /// version mean nothing.
  final String version;

  /// Latest generation per storage volume (e.g. `external_primary`, an SD
  /// card id). Generations are per volume and never compared across them.
  final Map<String, int> generations;

  /// Audio rows across all external volumes (deletions lower it).
  final int audioCount;

  factory MediaStoreCheckpoint.fromMap(Map<Object?, Object?> map) =>
      MediaStoreCheckpoint(
        version: map['version']! as String,
        generations: {
          for (final e in (map['generations']! as Map).entries)
            e.key as String: (e.value as num).toInt(),
        },
        audioCount: (map['count']! as num).toInt(),
      );

  @override
  List<Object?> get props => [version, generations, audioCount];
}

/// One audio file as MediaStore describes it.
class AudioFileRecord {
  const AudioFileRecord({
    required this.id,
    required this.path,
    this.uri,
    this.title,
    this.artist,
    this.album,
    this.albumId,
    this.durationMs,
    this.size = 0,
    this.dateAddedSeconds,
    this.isMusic,
    this.isAlarm,
    this.isNotification,
    this.isRingtone,
    this.isPodcast,
    this.isAudioBook,
  });

  final int id;
  final String path;
  final String? uri;
  final String? title;
  final String? artist;
  final String? album;
  final int? albumId;
  final int? durationMs;
  final int size;
  final int? dateAddedSeconds;
  final bool? isMusic;
  final bool? isAlarm;
  final bool? isNotification;
  final bool? isRingtone;
  final bool? isPodcast;
  final bool? isAudioBook;

  factory AudioFileRecord.fromMap(Map<Object?, Object?> map) {
    int? asInt(Object? v) => (v as num?)?.toInt();
    bool? asBool(Object? v) => v == null ? null : asInt(v) != 0;
    return AudioFileRecord(
      id: asInt(map['id'])!,
      path: map['path']! as String,
      uri: map['uri'] as String?,
      title: map['title'] as String?,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      albumId: asInt(map['albumId']),
      durationMs: asInt(map['duration']),
      size: asInt(map['size']) ?? 0,
      dateAddedSeconds: asInt(map['dateAdded']),
      isMusic: asBool(map['isMusic']),
      isAlarm: asBool(map['isAlarm']),
      isNotification: asBool(map['isNotification']),
      isRingtone: asBool(map['isRingtone']),
      isPodcast: asBool(map['isPodcast']),
      isAudioBook: asBool(map['isAudioBook']),
    );
  }

  /// The song this file is, or null if it isn't music (same rules as the
  /// full scan).
  LocalSong? toLocalSong() => buildMusicLocalSong(
    id: id,
    path: path,
    uri: uri,
    title: title,
    artist: artist,
    album: album,
    albumId: albumId,
    durationMs: durationMs,
    size: size,
    dateAddedSeconds: dateAddedSeconds,
    isMusic: isMusic,
    isAlarm: isAlarm,
    isNotification: isNotification,
    isRingtone: isRingtone,
    isPodcast: isPodcast,
    isAudioBook: isAudioBook,
  );
}

/// What changed in MediaStore since a checkpoint.
class AudioLibraryChanges {
  const AudioLibraryChanges({
    required this.checkpoint,
    required this.changed,
    required this.allIds,
  });

  /// Taken right before the rows were read: anything changing during the read
  /// has a later generation and is picked up by the next sync.
  final MediaStoreCheckpoint checkpoint;

  /// Rows added or modified (including renamed / moved) since the requested
  /// generations.
  final List<AudioFileRecord> changed;

  /// Every audio row id currently in MediaStore (ids only), to find
  /// deletions: generations never report deleted rows.
  final Set<int> allIds;
}

/// Every audio row MediaStore has, read in one complete pass.
class AudioFullScan {
  const AudioFullScan({required this.checkpoint, required this.records});

  /// Taken right before the rows were read; null before Android 11.
  final MediaStoreCheckpoint? checkpoint;

  /// All audio rows (music and non-music; filtering happens in Dart). Empty
  /// only when every query succeeded and MediaStore really has no audio.
  final List<AudioFileRecord> records;
}

/// Reads MediaStore's audio library, incrementally where possible.
///
/// Errors are never reported as empty results:
/// - no read permission → [MediaPermissionException]
/// - a failed / partial query → [MediaQueryException]
abstract interface class AudioLibraryDeltaSource {
  /// The current checkpoint, or null ONLY when this device has no
  /// generations (Android 10 and older, other platforms). Failures throw.
  Future<MediaStoreCheckpoint?> currentCheckpoint();

  /// Rows with a generation greater than [since] for each volume listed in
  /// it. Volumes not in [since] (newly inserted) are read entirely; volumes
  /// no longer present are ignored. Throws if any query fails.
  Future<AudioLibraryChanges> changesSince(Map<String, int> since);

  /// Every audio row, or null when this platform has no native scan (then
  /// the caller uses [MusicService]). Throws if any query fails.
  Future<AudioFullScan?> fullScan();
}

/// [AudioLibraryDeltaSource] over a small platform channel in `MainActivity`.
class MediaStoreDeltaSource implements AudioLibraryDeltaSource {
  const MediaStoreDeltaSource({@visibleForTesting bool? isAndroid})
    : _isAndroidOverride = isAndroid;

  final bool? _isAndroidOverride;
  bool get _isAndroid => _isAndroidOverride ?? Platform.isAndroid;

  static const MethodChannel _channel = MethodChannel('melodix/media_store');

  @override
  Future<MediaStoreCheckpoint?> currentCheckpoint() async {
    if (!_isAndroid) return null;
    // Null from the device means "no generations" (Android 10 and older).
    final map = await _invoke('audioCheckpoint');
    return map == null ? null : _parse(() => MediaStoreCheckpoint.fromMap(map));
  }

  @override
  Future<AudioLibraryChanges> changesSince(Map<String, int> since) async {
    if (!_isAndroid) {
      throw const MediaQueryException('Generations need Android 11+');
    }
    final map = await _invoke('audioChangesSince', {'since': since});
    if (map == null) {
      throw const MediaQueryException('No MediaStore changes returned');
    }
    return _parse(() => parseAudioLibraryChanges(map));
  }

  @override
  Future<AudioFullScan?> fullScan() async {
    if (!_isAndroid) return null;
    final map = await _invoke('audioFullScan');
    if (map == null) {
      throw const MediaQueryException('No MediaStore scan returned');
    }
    return _parse(() => parseAudioFullScan(map));
  }

  /// Calls [method], turning the device's errors into typed exceptions.
  static Future<Map<Object?, Object?>?> _invoke(
    String method, [
    Object? arguments,
  ]) async {
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(
        method,
        arguments,
      );
    } on PlatformException catch (e) {
      throw mediaStoreError(e);
    } on MissingPluginException {
      throw MediaQueryException('$method is not available');
    }
  }

  /// A malformed answer is a failed query, never an empty one.
  static T _parse<T>(T Function() parse) {
    try {
      return parse();
    } catch (e) {
      throw MediaQueryException('Unreadable MediaStore answer: $e');
    }
  }
}

/// The typed exception for an error from the `melodix/media_store` channel.
Exception mediaStoreError(PlatformException e) => e.code == 'permission_denied'
    ? const MediaPermissionException(permanentlyDenied: false)
    : MediaQueryException('${e.code}: ${e.message}');

/// Reads the `audioChangesSince` answer.
AudioLibraryChanges parseAudioLibraryChanges(Map<Object?, Object?> map) =>
    AudioLibraryChanges(
      checkpoint: MediaStoreCheckpoint.fromMap(
        map['checkpoint']! as Map<Object?, Object?>,
      ),
      changed: [
        for (final row in map['changed']! as List)
          AudioFileRecord.fromMap(row as Map<Object?, Object?>),
      ],
      allIds: {for (final id in map['ids']! as List) (id as num).toInt()},
    );

/// Reads the `audioFullScan` answer.
AudioFullScan parseAudioFullScan(Map<Object?, Object?> map) {
  final checkpoint = map['checkpoint'] as Map<Object?, Object?>?;
  return AudioFullScan(
    checkpoint: checkpoint == null
        ? null
        : MediaStoreCheckpoint.fromMap(checkpoint),
    records: [
      for (final row in map['rows']! as List)
        AudioFileRecord.fromMap(row as Map<Object?, Object?>),
    ],
  );
}

/// Serialises the saved sync checkpoint (with the music filter's rules
/// version) for storage.
String encodeSyncCheckpoint(
  MediaStoreCheckpoint checkpoint,
  int rulesVersion,
) => jsonEncode({
  'rules': rulesVersion,
  'version': checkpoint.version,
  'generations': checkpoint.generations,
  'count': checkpoint.audioCount,
});

/// The saved checkpoint and the rules version it was made with, or null if
/// [raw] is missing or unreadable (then a full scan is needed).
({MediaStoreCheckpoint checkpoint, int rulesVersion})? decodeSyncCheckpoint(
  String? raw,
) {
  if (raw == null) return null;
  try {
    final map = jsonDecode(raw) as Map<String, Object?>;
    return (
      checkpoint: MediaStoreCheckpoint.fromMap(map),
      rulesVersion: (map['rules']! as num).toInt(),
    );
  } catch (_) {
    return null;
  }
}
