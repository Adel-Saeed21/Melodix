/// How the app talks to OpenSubtitles (REST API v1).
///
/// The one place the API key is read. It's never in the source: it comes
/// from `config/opensubtitles.json` (git-ignored; see
/// `config/opensubtitles.example.json`) at build time,
///
///   flutter run --dart-define-from-file=config/opensubtitles.json
///
/// Without one, online search is simply off; local subtitles still work.
///
/// Note: a key given this way is compiled into the app. Keeping it out of
/// git stops accidental commits; it doesn't hide it from someone taking
/// the app apart (obfuscation only makes that harder).
class OpenSubtitlesConfig {
  const OpenSubtitlesConfig({
    required this.apiKey,
    this.baseUrl = defaultBaseUrl,
    this.userAgent = 'Melodix v1.0',
    this.minRequestInterval = const Duration(milliseconds: 250),
  });

  /// From the build (`--dart-define`).
  factory OpenSubtitlesConfig.fromEnvironment() => const OpenSubtitlesConfig(
    apiKey: String.fromEnvironment('OPENSUBTITLES_API_KEY'),
  );

  static const String defaultBaseUrl = 'https://api.opensubtitles.com/api/v1/';

  final String apiKey;
  final String baseUrl;

  /// The service requires an app name and version here.
  final String userAgent;

  /// The service allows a few requests a second; the app stays under it.
  final Duration minRequestInterval;

  bool get isConfigured => apiKey.trim().isNotEmpty;

  /// Never prints the key (e.g. in a log or an error).
  @override
  String toString() =>
      'OpenSubtitlesConfig(baseUrl: $baseUrl, apiKey: '
      '${isConfigured ? '<set>' : '<missing>'})';
}
