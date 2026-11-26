import 'dart:async';
import 'dart:typed_data';

import 'package:melodix/features/video/domain/repositories/video_media_repository.dart';

/// A video's thumbnail (cached; synchronous when it's in memory).
///
/// Thumbnails come in a few standard sizes ([standardSize]): screens ask
/// for slightly different sizes (a 104 or 112 dp row, a 176 dp card…), and
/// each distinct size was a separate decode on the device and a separate
/// cache entry. Rounded up, nearby sizes share one.
class GetVideoThumbnailUseCase {
  const GetVideoThumbnailUseCase(this.repository);

  final VideoMediaRepository repository;

  /// The standard sizes, in pixels (long side).
  static const List<int> sizes = [384, 768, 1024];

  /// [pixels] rounded up to a standard size (the largest one at most).
  static int standardSize(int pixels) {
    for (final size in sizes) {
      if (pixels <= size) return size;
    }
    return sizes.last;
  }

  FutureOr<Uint8List?> call(String videoId, {required int size}) =>
      repository.thumbnail(videoId, size: standardSize(size));

  /// The thumbnail if it's in memory already, without loading.
  ({Uint8List? bytes})? cached(String videoId, {required int size}) =>
      repository.cachedThumbnail(videoId, size: standardSize(size));
}
