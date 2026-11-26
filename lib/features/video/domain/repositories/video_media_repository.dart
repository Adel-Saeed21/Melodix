import 'dart:async';
import 'dart:typed_data';

/// What's read from the device for a video itself: its thumbnail, and
/// what the player opens.
abstract interface class VideoMediaRepository {
  /// The video's thumbnail at about [size] px, or null if it has none.
  /// Cached: a cached answer comes back synchronously, and concurrent
  /// requests for the same thumbnail share one load.
  FutureOr<Uint8List?> thumbnail(String videoId, {int size = 300});

  /// The thumbnail if it's in memory already, without loading: null when
  /// not cached; a record (whose bytes may be null: none) when it is.
  ({Uint8List? bytes})? cachedThumbnail(String videoId, {int size = 300});

  /// What the video player should open (a `content://` URI on Android), or
  /// null if the video is gone.
  Future<Uri?> playbackUri(String videoId);
}
