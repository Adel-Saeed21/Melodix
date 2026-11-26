/// "01:35", or "1:02:05" for an hour or more.
String formatPlaybackTime(Duration duration) {
  final d = duration.isNegative ? Duration.zero : duration;
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

/// "01:35 / -02:40": elapsed, then time remaining.
String formatElapsedAndRemaining(Duration position, Duration remaining) =>
    '${formatPlaybackTime(position)} / -${formatPlaybackTime(remaining)}';
