import 'dart:async';
import 'dart:typed_data';

import 'package:melodix/features/music_library/domain/repositories/artwork_repository.dart';

class SongArtworkParams {
  const SongArtworkParams(this.songId, {this.size = 200});

  final int songId;

  /// Requested width/height in pixels.
  final int size;
}

/// Embedded cover art for a song, or null if it has none.
class GetSongArtworkUseCase {
  const GetSongArtworkUseCase(this.repository);

  final ArtworkRepository repository;

  /// Synchronous when the cover is cached (see [ArtworkRepository]).
  /// The cover if it's in memory already, without loading (see
  /// [ArtworkRepository.cachedArtwork]).
  ({Uint8List? bytes})? cached(SongArtworkParams params) =>
      repository.cachedArtwork(params.songId, size: params.size);

  FutureOr<Uint8List?> call(SongArtworkParams params) =>
      repository.getArtwork(params.songId, size: params.size);
}
