import 'package:equatable/equatable.dart';

/// Where a song's lyrics came from.
enum LyricsSource {
  /// Written inside the audio file (its tags).
  embedded,

  /// An `.lrc` file next to the song.
  file,

  /// Found online (LRCLIB) and saved on the phone.
  online,
}

/// One line; [time] is when it's sung (null in unsynced lyrics).
class LyricLine extends Equatable {
  const LyricLine(this.text, {this.time});

  final String text;
  final Duration? time;

  @override
  List<Object?> get props => [text, time];
}

/// A song's lyrics: synced (each line timed, so the screen follows the
/// song) or plain text.
class Lyrics extends Equatable {
  const Lyrics({required this.lines, required this.source});

  final List<LyricLine> lines;
  final LyricsSource source;

  bool get isSynced => lines.isNotEmpty && lines.first.time != null;

  /// The line being sung at [position] (the last line started), or -1
  /// before the first. Always -1 for plain lyrics.
  int lineAt(Duration position) {
    if (!isSynced) return -1;
    var low = 0;
    var high = lines.length - 1;
    var found = -1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (lines[mid].time! <= position) {
        found = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return found;
  }

  @override
  List<Object?> get props => [lines, source];
}
