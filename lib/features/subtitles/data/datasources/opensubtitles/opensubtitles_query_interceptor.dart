import 'package:dio/dio.dart';

/// Writes query strings the way OpenSubtitles wants them: parameters in
/// alphabetical order, values in lower case, spaces as `+`.
///
/// Anything else (e.g. `?query=The%20Matrix&languages=en`) gets a 301
/// redirect to the "right" URL instead of results, so every search would
/// fail or cost an extra round trip.
class OpenSubtitlesQueryInterceptor extends Interceptor {
  const OpenSubtitlesQueryInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final params = options.queryParameters;
    if (params.isNotEmpty) {
      final query = canonicalQuery(params);
      options
        ..queryParameters = {}
        ..path = query.isEmpty ? options.path : '${options.path}?$query';
    }
    handler.next(options);
  }

  /// `{query: 'The Matrix', languages: 'en'}` → `languages=en&query=the+matrix`
  /// (nulls dropped).
  static String canonicalQuery(Map<String, dynamic> params) {
    final keys = [
      for (final e in params.entries)
        if (e.value != null) e.key.toLowerCase(),
    ]..sort();
    final values = {
      for (final e in params.entries)
        if (e.value != null) e.key.toLowerCase(): '${e.value}'.toLowerCase(),
    };
    return [
      for (final key in keys)
        '${Uri.encodeQueryComponent(key)}='
            '${Uri.encodeQueryComponent(values[key]!)}',
    ].join('&');
  }
}
