import 'package:equatable/equatable.dart';

/// One caption: [text] is shown from [start] until [end].
class SubtitleCue extends Equatable {
  const SubtitleCue({
    required this.start,
    required this.end,
    required this.text,
  });

  final Duration start;
  final Duration end;

  /// Plain text (formatting tags removed); may hold line breaks.
  final String text;

  bool shows(Duration position) => position >= start && position < end;

  @override
  List<Object?> get props => [start, end, text];
}

/// A video's captions in time order, with a fast "what's on screen now".
class SubtitleTimeline {
  SubtitleTimeline(List<SubtitleCue> cues)
    : cues = List.unmodifiable(
        [...cues]..sort((a, b) => a.start.compareTo(b.start)),
      );

  static final SubtitleTimeline empty = SubtitleTimeline(const []);

  final List<SubtitleCue> cues;

  bool get isEmpty => cues.isEmpty;

  /// The text showing at [position] (overlapping cues one per line), or
  /// null when none is.
  String? textAt(Duration position) {
    // The last cue starting at or before [position] (binary search).
    var low = 0;
    var high = cues.length - 1;
    var last = -1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (cues[mid].start <= position) {
        last = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    if (last < 0) return null;
    // Earlier cues can still be showing (overlaps); they're rare and
    // short, so a few steps back is enough.
    final showing = <String>[];
    for (var i = last; i >= 0 && i > last - 8; i--) {
      if (cues[i].shows(position)) showing.insert(0, cues[i].text);
    }
    return showing.isEmpty ? null : showing.join('\n');
  }
}
