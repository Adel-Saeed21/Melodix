import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/music_library/presentation/logic/song_playback.dart';

/// Builds with whether [songId] is the song playing now and whether it's
/// playing. Rebuilds only when that changes for this song (not on position
/// ticks, which [SongPlayback] doesn't carry). Without a [SongPlayback]
/// above it (e.g. an isolated widget test) it reports "not current".
class CurrentSongBuilder extends StatefulWidget {
  const CurrentSongBuilder({
    super.key,
    required this.songId,
    required this.builder,
  });

  final int songId;
  final Widget Function(BuildContext context, bool isCurrent, bool isPlaying)
  builder;

  @override
  State<CurrentSongBuilder> createState() => _CurrentSongBuilderState();
}

class _CurrentSongBuilderState extends State<CurrentSongBuilder> {
  SongPlayback? _playback;
  Stream<(bool, bool)>? _marks;

  /// This song's mark in [song]: (is it current, is it playing).
  (bool, bool) _mark(CurrentSong song) {
    final isCurrent = song.songId == widget.songId;
    return (isCurrent, isCurrent && song.isPlaying);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final playback = SongPlayback.maybeOf(context);
    if (!identical(playback, _playback)) _follow(playback);
  }

  @override
  void didUpdateWidget(CurrentSongBuilder old) {
    super.didUpdateWidget(old);
    if (old.songId != widget.songId) _follow(_playback);
  }

  void _follow(SongPlayback? playback) {
    _playback = playback;
    _marks = playback?.changes.map(_mark).distinct();
  }

  @override
  Widget build(BuildContext context) {
    final playback = _playback;
    final marks = _marks;
    if (playback == null || marks == null) {
      return widget.builder(context, false, false);
    }
    return StreamBuilder<(bool, bool)>(
      stream: marks,
      initialData: _mark(playback.current),
      builder: (context, snapshot) {
        final (isCurrent, isPlaying) = snapshot.requireData;
        return widget.builder(context, isCurrent, isPlaying);
      },
    );
  }
}
