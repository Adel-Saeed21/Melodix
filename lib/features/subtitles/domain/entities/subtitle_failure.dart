import 'package:melodix/core/errors/failures.dart';

/// Why something about subtitles didn't work. Each kind gets its own
/// message on screen, and none of them stops the video.
sealed class SubtitleFailure extends Failure {
  const SubtitleFailure(super.message);
}

/// The file isn't SRT or WebVTT, or holds no readable captions.
class SubtitleFormatFailure extends SubtitleFailure {
  const SubtitleFormatFailure([
    super.message = 'This subtitle file can’t be read.',
  ]);
}

/// Reading or saving the app's subtitle files failed.
class SubtitleStorageFailure extends SubtitleFailure {
  const SubtitleStorageFailure([
    super.message = 'The subtitles couldn’t be saved or read.',
  ]);
}

/// Online search isn't set up in this build (no API key).
class SubtitleNotConfiguredFailure extends SubtitleFailure {
  const SubtitleNotConfiguredFailure([
    super.message = 'Online subtitles aren’t set up in this version.',
  ]);
}

/// No internet, or the server couldn't be reached.
class SubtitleNetworkFailure extends SubtitleFailure {
  const SubtitleNetworkFailure([
    super.message = 'No connection. Check your internet and try again.',
  ]);
}

/// The service refused the app's key (401 on a search). Users can't fix
/// it, so the message doesn't talk about keys.
class SubtitleAuthFailure extends SubtitleFailure {
  const SubtitleAuthFailure([
    super.message = 'Online subtitles aren’t available right now.',
  ]);
}

/// The service refused a download (401 on `/download`).
class SubtitleDownloadNotAllowedFailure extends SubtitleFailure {
  const SubtitleDownloadNotAllowedFailure([
    super.message = 'This subtitle can’t be downloaded right now.',
  ]);
}

/// Too many requests in a short time.
class SubtitleRateLimitFailure extends SubtitleFailure {
  const SubtitleRateLimitFailure({this.retryAfter})
    : super('Too many requests. Wait a moment and try again.');

  final Duration? retryAfter;

  @override
  List<Object?> get props => [message, retryAfter];
}

/// The day's download allowance is used up.
class SubtitleQuotaFailure extends SubtitleFailure {
  const SubtitleQuotaFailure({this.resetsIn})
    : super('Daily download limit reached.');

  /// As the service says it (e.g. "5 hours").
  final String? resetsIn;

  @override
  List<Object?> get props => [message, resetsIn];
}

/// Anything else the service got wrong.
class SubtitleServiceFailure extends SubtitleFailure {
  const SubtitleServiceFailure([
    super.message = 'The subtitle service had a problem. Try again later.',
  ]);
}
