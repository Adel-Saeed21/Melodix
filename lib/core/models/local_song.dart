import 'package:equatable/equatable.dart';

/// An audio file found in the device's local storage.
class LocalSong extends Equatable {
  const LocalSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumId,
    required this.duration,
    required this.path,
    required this.uri,
    required this.size,
    this.dateAdded,
  });

  /// MediaStore id; also used to load artwork.
  final int id;
  final String title;
  final String artist;
  final String album;
  final int? albumId;
  final Duration duration;

  /// Absolute file path.
  final String path;

  /// Content URI (Android); preferred for playback when available.
  final String? uri;

  /// File size in bytes.
  final int size;

  /// When the file was added to the device (MediaStore DATE_ADDED), if known.
  final DateTime? dateAdded;

  @override
  List<Object?> get props => [id, path];
}
