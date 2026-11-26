import 'package:equatable/equatable.dart';

class Artist extends Equatable {
  const Artist({
    required this.name,
    required this.songCount,
    required this.albumCount,
    required this.artworkSongId,
  });

  final String name;
  final int songCount;
  final int albumCount;

  final int artworkSongId;

  @override
  List<Object?> get props => [name, songCount, albumCount, artworkSongId];
}
