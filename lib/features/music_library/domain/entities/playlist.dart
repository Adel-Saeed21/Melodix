import 'package:equatable/equatable.dart';

class Playlist extends Equatable {
  const Playlist({
    required this.id,
    required this.name,
    required this.songCount,
    required this.isFavorite,
    required this.artworkSongId,
  });

  final int id;
  final String name;
  final int songCount;
  final bool isFavorite;

  /// The first song, whose cover can represent the playlist; null if empty.
  final int? artworkSongId;

  @override
  List<Object?> get props => [id, name, songCount, isFavorite, artworkSongId];
}
