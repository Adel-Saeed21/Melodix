/// "3:07", or "1:02:05" for an hour or more.
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
  }
  return '$minutes:$seconds';
}

/// A list's total length in words: "48 min", "2 hr 14 min" ("1 min" at
/// least, once there's anything).
String formatTotalDuration(Duration duration) {
  if (duration <= Duration.zero) return '0 min';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '${minutes < 1 ? 1 : minutes} min';
  return minutes == 0 ? '$hours hr' : '$hours hr $minutes min';
}
