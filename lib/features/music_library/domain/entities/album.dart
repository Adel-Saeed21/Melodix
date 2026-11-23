import 'package:equatable/equatable.dart';

class Album extends Equatable {
  const Album({
    required this.albumId,
    required this.title,
    required this.artist,
    required this.songCount,
    required this.duration,
    required this.artworkSongId,
  });

  /// MediaStore album id; null when the device didn't report one.
  final int? albumId;
  final String title;

  /// The album's artist, or "Various artists" when songs differ.
  final String artist;
  final int songCount;

  /// Total length of all songs.
  final Duration duration;

  /// A song whose embedded artwork can represent the album.
  final int artworkSongId;

  @override
  List<Object?> get props => [
    albumId,
    title,
    artist,
    songCount,
    duration,
    artworkSongId,
  ];
}
