import 'package:flutter/services.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/core/models/local_song.dart';
import 'package:melodix/core/service/audio_library_delta_source.dart';
import 'package:melodix/core/service/music_service.dart';
import 'package:melodix/core/service/permission_handling_service.dart';

/// How a simulated native MediaStore query fails.
enum NativeFault {
  /// The query throws a SecurityException (native: "permission_denied").
  securityException,

  /// ContentResolver.query returns null (native: "query_failed").
  nullCursor,
}

/// An in-memory MediaStore for tests: audio rows on one or more volumes,
/// each volume with its own generation counter (bumped on every insert or
/// update, like Android 11+).
///
/// The [AudioLibraryDeltaSource] side follows `MainActivity`'s channel
/// contract (permission check first, "permission_denied" / "query_failed"
/// errors, no partial answers) and goes through the same error mapping and
/// parsing as [MediaStoreDeltaSource]. The [MusicService] side behaves like
/// on_audio_query, including its weakness: a null cursor gives an empty
/// list. It is also the [PermissionHandlingService], so the app's permission
/// status and the device's own check can be set together or apart.
class FakeMediaStore
    implements
        AudioLibraryDeltaSource,
        MusicService,
        PermissionHandlingService {
  FakeMediaStore({List<String> volumes = const ['external_primary']}) {
    for (final volume in volumes) {
      _generations[volume] = 0;
    }
  }

  String version = 'v1';
  final Map<String, int> _generations = {};
  final Map<int, _Row> _rows = {};
  int _nextId = 1;

  /// Set to make the next call fail with a null cursor.
  bool failNextChanges = false;
  bool failNextFullScan = false;

  /// What permission_handler reports to the app.
  MediaPermissionStatus permission = MediaPermissionStatus.granted;

  /// The native side's own permission check; follows [permission] unless
  /// set (e.g. revoked between the app's check and the query).
  bool? nativePermission;
  bool get _nativeGranted => nativePermission ?? permission.isGranted;

  /// Persistent faults, per query (cleared by setting them back to null).
  NativeFault? checkpointFault;
  NativeFault? changedQueryFault;
  NativeFault? idsQueryFault;
  NativeFault? fullScanFault;

  /// A volume whose query returns no cursor (e.g. SD card being ejected).
  String? unavailableVolume;

  /// False: no native full scan (the platform uses [MusicService]).
  bool nativeFullScan = true;

  /// Calls to the native side, by method name.
  final Map<String, int> nativeCalls = {};

  /// For measurements.
  int fullScans = 0;
  int deltaQueries = 0;
  int rowsTransferred = 0;

  /// When false, [currentCheckpoint] returns null (Android 10 / iOS).
  bool supportsGenerations = true;

  // ---- simulated file operations ----

  int add({
    String volume = 'external_primary',
    required String title,
    String artist = 'Artist',
    String album = 'Album',
    String? path,
    int durationMs = 200000,
  }) {
    final id = _nextId++;
    _rows[id] = _Row(
      volume: volume,
      generation: _bump(volume),
      record: AudioFileRecord(
        id: id,
        path: path ?? '/storage/$volume/Music/$title.mp3',
        uri: 'content://media/external/audio/media/$id',
        title: title,
        artist: artist,
        album: album,
        albumId: album.hashCode,
        durationMs: durationMs,
        size: 1000,
        dateAddedSeconds: 1767225600 + id,
        isMusic: true,
      ),
    );
    return id;
  }

  /// Tag edit (e.g. the title changed).
  void modify(int id, {String? title, String? artist}) {
    final row = _rows[id]!;
    _rows[id] = row.withRecord(
      _bump(row.volume),
      _copy(row.record, title: title, artist: artist),
    );
  }

  void rename(int id, String newPath) {
    final row = _rows[id]!;
    _rows[id] = row.withRecord(
      _bump(row.volume),
      _copy(row.record, path: newPath),
    );
  }

  /// Moves to another folder or volume (same row id, new path / volume).
  void move(int id, {required String newPath, String? toVolume}) {
    final row = _rows[id]!;
    final volume = toVolume ?? row.volume;
    _rows[id] = _Row(
      volume: volume,
      generation: _bump(volume),
      record: _copy(row.record, path: newPath),
    );
  }

  /// Deleting never bumps a generation (rows just disappear).
  void delete(int id) => _rows.remove(id);

  /// MediaStore rebuilt its database: new version, generations restart.
  void rebuildDatabase() {
    version = 'v${int.parse(version.substring(1)) + 1}';
    for (final volume in _generations.keys) {
      _generations[volume] = 0;
    }
  }

  void insertVolume(String volume) => _generations[volume] = 0;

  /// The volume (e.g. an SD card) is removed: its rows disappear.
  void removeVolume(String volume) {
    _generations.remove(volume);
    _rows.removeWhere((_, row) => row.volume == volume);
  }

  int _bump(String volume) => _generations[volume] = _generations[volume]! + 1;

  // ---- simulated MainActivity ("melodix/media_store") ----

  void _requirePermission() {
    if (!_nativeGranted) {
      throw PlatformException(code: 'permission_denied', message: 'denied');
    }
  }

  static void _fault(NativeFault? fault, String query) {
    switch (fault) {
      case NativeFault.securityException:
        throw PlatformException(code: 'permission_denied', message: query);
      case NativeFault.nullCursor:
        throw PlatformException(code: 'query_failed', message: 'no cursor');
      case null:
        return;
    }
  }

  Map<Object?, Object?> _nativeCheckpointR() {
    _fault(checkpointFault, 'count');
    return {
      'version': version,
      'generations': Map<Object?, Object?>.of(_generations),
      'count': _rows.length,
    };
  }

  Map<Object?, Object?>? _audioCheckpoint() {
    _count('audioCheckpoint');
    if (!supportsGenerations) return null;
    _requirePermission();
    return _nativeCheckpointR();
  }

  Map<Object?, Object?> _audioChangesSince(Map<String, int> since) {
    _count('audioChangesSince');
    if (!supportsGenerations) {
      throw PlatformException(code: 'query_failed', message: 'API < 30');
    }
    _requirePermission();
    final checkpoint = _nativeCheckpointR(); // taken before reading rows
    final changed = <Map<Object?, Object?>>[];
    for (final volume in _generations.keys) {
      if (volume == unavailableVolume) {
        throw PlatformException(code: 'query_failed', message: volume);
      }
      _fault(changedQueryFault, 'changed');
      if (failNextChanges) {
        failNextChanges = false;
        throw PlatformException(code: 'query_failed', message: 'no cursor');
      }
      for (final row in _rows.values) {
        if (row.volume == volume && row.generation > (since[volume] ?? 0)) {
          changed.add(_toMap(row.record));
        }
      }
    }
    _fault(idsQueryFault, 'ids');
    return {
      'checkpoint': checkpoint,
      'changed': changed,
      'ids': [..._rows.keys],
    };
  }

  Map<Object?, Object?> _audioFullScan() {
    _count('audioFullScan');
    _requirePermission();
    final checkpoint = supportsGenerations ? _nativeCheckpointR() : null;
    _fault(fullScanFault, 'rows');
    if (failNextFullScan) {
      failNextFullScan = false;
      throw PlatformException(code: 'query_failed', message: 'no cursor');
    }
    return {
      'checkpoint': checkpoint,
      'rows': [for (final row in _rows.values) _toMap(row.record)],
    };
  }

  void _count(String method) =>
      nativeCalls[method] = (nativeCalls[method] ?? 0) + 1;

  /// Runs a native call, mapping errors like [MediaStoreDeltaSource].
  static T _channel<T>(T Function() call) {
    try {
      return call();
    } on PlatformException catch (e) {
      throw mediaStoreError(e);
    }
  }

  // ---- AudioLibraryDeltaSource ----

  @override
  Future<MediaStoreCheckpoint?> currentCheckpoint() async {
    final map = _channel(_audioCheckpoint);
    return map == null ? null : MediaStoreCheckpoint.fromMap(map);
  }

  @override
  Future<AudioLibraryChanges> changesSince(Map<String, int> since) async {
    deltaQueries++;
    final changes = parseAudioLibraryChanges(
      _channel(() => _audioChangesSince(since)),
    );
    rowsTransferred += changes.changed.length;
    return changes;
  }

  @override
  Future<AudioFullScan?> fullScan() async {
    if (!nativeFullScan) return null;
    fullScans++;
    final scan = parseAudioFullScan(_channel(_audioFullScan));
    rowsTransferred += scan.records.length;
    return scan;
  }

  static Map<Object?, Object?> _toMap(AudioFileRecord r) {
    int? flag(bool? v) => v == null ? null : (v ? 1 : 0);
    return {
      'id': r.id,
      'path': r.path,
      'uri': r.uri,
      'title': r.title,
      'artist': r.artist,
      'album': r.album,
      'albumId': r.albumId,
      'duration': r.durationMs,
      'size': r.size,
      'dateAdded': r.dateAddedSeconds,
      'isMusic': flag(r.isMusic),
      'isAlarm': flag(r.isAlarm),
      'isNotification': flag(r.isNotification),
      'isRingtone': flag(r.isRingtone),
      'isPodcast': flag(r.isPodcast),
      'isAudioBook': flag(r.isAudioBook),
    };
  }

  // ---- MusicService (full scan, like on_audio_query) ----

  @override
  Future<List<LocalSong>> getAllSongs() async {
    fullScans++;
    if (!permission.isGranted) {
      throw MediaPermissionException(
        permanentlyDenied:
            permission == MediaPermissionStatus.permanentlyDenied,
      );
    }
    final failed = failNextFullScan || fullScanFault != null;
    failNextFullScan = false;
    if (failed) {
      // on_audio_query loops `while (cursor != null && ...)`: a failed
      // query looks exactly like an empty library.
      return const [];
    }
    rowsTransferred += _rows.length;
    return [for (final row in _rows.values) ?row.record.toLocalSong()];
  }

  @override
  Future<Uint8List?> getArtwork(int songId, {int size = 200}) async => null;

  // ---- PermissionHandlingService ----

  @override
  Future<MediaPermissionStatus> audioStatus() async => permission;

  @override
  Future<MediaPermissionStatus> requestAudio() async => permission;

  @override
  Future<MediaPermissionStatus> videoStatus() async =>
      MediaPermissionStatus.granted;

  @override
  Future<MediaPermissionStatus> requestVideo() async =>
      MediaPermissionStatus.granted;

  @override
  Future<bool> isVideoAccessPartial() async => false;

  @override
  Future<bool> openSettings() async => false;

  @override
  bool get canDeleteSongs => false;

  @override
  Future<List<int>> deleteSongs(List<int> songIds) async => const [];

  static AudioFileRecord _copy(
    AudioFileRecord r, {
    String? title,
    String? artist,
    String? path,
  }) => AudioFileRecord(
    id: r.id,
    path: path ?? r.path,
    uri: r.uri,
    title: title ?? r.title,
    artist: artist ?? r.artist,
    album: r.album,
    albumId: r.albumId,
    durationMs: r.durationMs,
    size: r.size,
    dateAddedSeconds: r.dateAddedSeconds,
    isMusic: r.isMusic,
  );
}

class _Row {
  const _Row({
    required this.volume,
    required this.generation,
    required this.record,
  });

  final String volume;
  final int generation;
  final AudioFileRecord record;

  _Row withRecord(int generation, AudioFileRecord record) =>
      _Row(volume: volume, generation: generation, record: record);
}
