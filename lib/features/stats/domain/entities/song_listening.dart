import 'package:equatable/equatable.dart';

/// What was listened to of one song: in the library now, or gone from it
/// (deleted, moved, its storage removed) with its history kept.
class SongListening extends Equatable {
  const SongListening({
    required this.id,
    required this.title,
    required this.artist,
    required this.playCount,
    required this.listened,
    this.isFavorite = false,
    this.inLibrary = true,
  });

  final int id;
  final String title;
  final String artist;
  final int playCount;

  /// Time really listened to (estimated for history from before that was
  /// kept).
  final Duration listened;
  final bool isFavorite;

  /// False for songs no longer on the device (kept for the stats only).
  final bool inLibrary;

  @override
  List<Object?> get props => [
    id,
    title,
    artist,
    playCount,
    listened,
    isFavorite,
    inLibrary,
  ];
}
