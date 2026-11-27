import 'package:equatable/equatable.dart';
import 'package:melodix/core/service/local_song_builder.dart';
import 'package:melodix/features/stats/domain/entities/song_listening.dart';

/// An artist and how often their songs were played.
typedef ArtistPlays = ({String artist, int plays});

/// What the user listens to: time listened, plays, top songs and top
/// artists, from the whole listening history (every saved song, whatever
/// the music filters show, and songs since removed from the device).
class ListeningStats extends Equatable {
  const ListeningStats({
    required this.listened,
    required this.plays,
    required this.songCount,
    required this.favourites,
    required this.topSongs,
    required this.topArtists,
  });

  static const empty = ListeningStats(
    listened: Duration.zero,
    plays: 0,
    songCount: 0,
    favourites: 0,
    topSongs: [],
    topArtists: [],
  );

  factory ListeningStats.of(List<SongListening> history, {int top = 5}) {
    var listened = Duration.zero;
    var plays = 0;
    var songCount = 0;
    var favourites = 0;
    final byArtist = <String, int>{};
    for (final song in history) {
      if (song.inLibrary) {
        songCount++;
        if (song.isFavorite) favourites++;
      }
      listened += song.listened;
      if (song.playCount <= 0) continue;
      plays += song.playCount;
      final artist = song.artist.trim();
      if (artist.isEmpty || artist == unknownArtist) continue;
      byArtist[artist] = (byArtist[artist] ?? 0) + song.playCount;
    }
    final played = [
      for (final s in history)
        if (s.playCount > 0) s,
    ]..sort((a, b) => b.playCount.compareTo(a.playCount));
    final artists = [
      for (final e in byArtist.entries) (artist: e.key, plays: e.value),
    ]..sort((a, b) => b.plays.compareTo(a.plays));
    return ListeningStats(
      listened: listened,
      plays: plays,
      songCount: songCount,
      favourites: favourites,
      topSongs: List.unmodifiable(played.take(top)),
      topArtists: List.unmodifiable(artists.take(top)),
    );
  }

  /// Time really listened to (paused, skipped and unheard parts excluded).
  final Duration listened;
  final int plays;

  /// Songs in the library now (all of them, whatever the filters show).
  final int songCount;
  final int favourites;

  /// Most played first.
  final List<SongListening> topSongs;
  final List<ArtistPlays> topArtists;

  bool get isEmpty => plays == 0 && listened == Duration.zero;

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
