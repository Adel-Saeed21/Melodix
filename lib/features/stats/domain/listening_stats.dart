import 'package:equatable/equatable.dart';
import 'package:melodix/core/service/local_song_builder.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

/// An artist and how often their songs were played.
typedef ArtistPlays = ({String artist, int plays});

/// What the user listens to, from the play counts the player keeps:
/// time listened, plays, top songs and top artists.
class ListeningStats extends Equatable {
  const ListeningStats({
    required this.listened,
    required this.plays,
    required this.songCount,
    required this.favourites,
    required this.topSongs,
    required this.topArtists,
  });

  factory ListeningStats.of(List<Song> songs, {int top = 5}) {
    var listened = Duration.zero;
    var plays = 0;
    var favourites = 0;
    final byArtist = <String, int>{};
    for (final song in songs) {
      if (song.isFavorite) favourites++;
      if (song.playCount <= 0) continue;
      plays += song.playCount;
      listened += song.duration * song.playCount;
      final artist = song.artist.trim();
      if (artist.isEmpty || artist == unknownArtist) continue;
      byArtist[artist] = (byArtist[artist] ?? 0) + song.playCount;
    }
    final played = [
      for (final s in songs)
        if (s.playCount > 0) s,
    ]..sort((a, b) => b.playCount.compareTo(a.playCount));
    final artists = [
      for (final e in byArtist.entries) (artist: e.key, plays: e.value),
    ]..sort((a, b) => b.plays.compareTo(a.plays));
    return ListeningStats(
      listened: listened,
      plays: plays,
      songCount: songs.length,
      favourites: favourites,
      topSongs: List.unmodifiable(played.take(top)),
      topArtists: List.unmodifiable(artists.take(top)),
    );
  }

  /// Song lengths × their plays (a song stopped early counts in full).
  final Duration listened;
  final int plays;
  final int songCount;
  final int favourites;

  /// Most played first.
  final List<Song> topSongs;
  final List<ArtistPlays> topArtists;

  bool get isEmpty => plays == 0;

  @override
  List<Object?> get props => [
    listened,
    plays,
    songCount,
    favourites,
    topSongs,
    topArtists,
  ];
}
