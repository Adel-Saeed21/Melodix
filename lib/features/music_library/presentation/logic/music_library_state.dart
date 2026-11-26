import 'package:equatable/equatable.dart';
import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_result.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

enum MusicLibraryStatus {
  initial,
  permissionRequired,
  scanning,
  ready,
  failure,
}

class MusicLibraryState extends Equatable {
  const MusicLibraryState({
    this.status = MusicLibraryStatus.initial,
    this.songs = const [],
    this.permission,
    this.isSyncing = false,
    this.syncStage,
    this.lastSyncResult,
    this.lastSyncedAt,
    this.errorMessage,
  });

  final MusicLibraryStatus status;
  final List<Song> songs;
  final LibraryPermission? permission;
  final bool isSyncing;

  /// How far the running sync got; null when none runs (or before it
  /// reports anything).
  final LibrarySyncStage? syncStage;

  /// What the last successful sync changed (e.g. for "Found 3 new songs").
  final LibrarySyncResult? lastSyncResult;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  bool get hasPermission => permission?.isGranted ?? false;

  MusicLibraryState copyWith({
    MusicLibraryStatus? status,
    List<Song>? songs,
    LibraryPermission? permission,
    bool? isSyncing,
    LibrarySyncStage? syncStage,
    bool clearSyncStage = false,
    LibrarySyncResult? lastSyncResult,
    DateTime? lastSyncedAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MusicLibraryState(
      status: status ?? this.status,
      songs: songs ?? this.songs,
      permission: permission ?? this.permission,
      isSyncing: isSyncing ?? this.isSyncing,
      syncStage: clearSyncStage ? null : syncStage ?? this.syncStage,
      lastSyncResult: lastSyncResult ?? this.lastSyncResult,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    songs,
    permission,
    isSyncing,
    syncStage,
    lastSyncResult,
    lastSyncedAt,
    errorMessage,
  ];
}
