import 'package:equatable/equatable.dart';

/// A song in the user's local library.
class Song extends Equatable {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumId,
    required this.duration,
    required this.path,
    required this.playbackUri,
    required this.isFavorite,
    required this.playCount,
    this.dateAdded,
  });

  final int id;
  final String title;
  final String artist;
  final String album;
  final int? albumId;
  final Duration duration;

  /// File path, for display only. Do not use it for playback.
  final String path;

  /// What the player should open. On Android this is a MediaStore content
  /// URI, which works under scoped storage where file paths may not.
  final Uri playbackUri;

  final bool isFavorite;

  /// How many times the song was played (see `RecordSongPlayUseCase`).
  final int playCount;

  /// When the file arrived on the device; null if unknown.
  final DateTime? dateAdded;

  @override
  List<Object?> get props => [
    id,
    title,
    artist,
    album,
    albumId,
    duration,
    path,
    playbackUri,
    isFavorite,
    playCount,
    dateAdded,
  ];
}
