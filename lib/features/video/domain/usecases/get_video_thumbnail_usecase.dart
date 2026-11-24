import 'dart:async';
import 'dart:typed_data';

import 'package:melodix/features/video/domain/repositories/video_library_repository.dart';

/// A video's thumbnail (cached; synchronous when it's in memory).
class GetVideoThumbnailUseCase {
  const GetVideoThumbnailUseCase(this.repository);

  final VideoLibraryRepository repository;

  FutureOr<Uint8List?> call(String videoId, {required int size}) =>
      repository.thumbnail(videoId, size: size);

  /// The thumbnail if it's in memory already, without loading.
  ({Uint8List? bytes})? cached(String videoId, {required int size}) =>
      repository.cachedThumbnail(videoId, size: size);
}
