import 'package:dio/dio.dart';

/// What LRCLIB has for a song: timed (LRC) and/or plain lyrics.
typedef OnlineLyricsText = ({String? synced, String? plain});

/// Why an online lookup didn't answer.
class LyricsLookupException implements Exception {
  const LyricsLookupException(this.message);

  final String message;

  @override
  String toString() => 'LyricsLookupException($message)';
}

/// LRCLIB (lrclib.net): a free, open lyrics database, no account or key.
///
/// Only the song's title, artist, album and length are sent, and only
/// when the user asks ("Search online").
class LrclibClient {
  LrclibClient([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://lrclib.net/api',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              // LRCLIB asks clients to name themselves.
              headers: {'User-Agent': 'Melodix/1.0 (music player app)'},
            ),
          );

  final Dio _dio;

  /// The best match, or null if LRCLIB has none.
  Future<OnlineLyricsText?> find({
    required String title,
    String? artist,
    String? album,
    Duration? duration,
  }) async {
    try {
      // An exact match first (title, artist, album, length).
      if (artist != null) {
        final exact = await _dio.get<Map<String, dynamic>>(
          '/get',
          queryParameters: {
            'track_name': title,
            'artist_name': artist,
            'album_name': ?album,
            if (duration != null && duration > Duration.zero)
              'duration': duration.inSeconds,
          },
          options: Options(validateStatus: (s) => s == 200 || s == 404),
        );
        final found = _text(exact.data);
        if (exact.statusCode == 200 && found != null) return found;
      }
      // Then a search; the closest in length with synced lyrics wins.
      final search = await _dio.get<List<dynamic>>(
        '/search',
        queryParameters: {'track_name': title, 'artist_name': ?artist},
      );
      final results = [
        for (final r in search.data ?? const [])
          if (r is Map<String, dynamic> && _text(r) != null) r,
      ];
      if (results.isEmpty) return null;
      int score(Map<String, dynamic> r) {
        final synced = r['syncedLyrics'] is String ? 0 : 1000;
        final length = (r['duration'] as num?)?.round();
        final off = duration == null || length == null
            ? 500
            : (length - duration.inSeconds).abs();
        return synced + off;
      }

      results.sort((a, b) => score(a).compareTo(score(b)));
      return _text(results.first);
    } on DioException catch (e) {
      throw LyricsLookupException(e.message ?? e.type.name);
    }
  }

  static OnlineLyricsText? _text(Map<String, dynamic>? r) {
    if (r == null || r['instrumental'] == true) return null;
    final synced = r['syncedLyrics'];
    final plain = r['plainLyrics'];
    final s = synced is String && synced.trim().isNotEmpty ? synced : null;
    final p = plain is String && plain.trim().isNotEmpty ? plain : null;
    if (s == null && p == null) return null;
    return (synced: s, plain: p);
  }
}
