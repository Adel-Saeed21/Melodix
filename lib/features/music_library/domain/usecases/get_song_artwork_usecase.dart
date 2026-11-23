import 'dart:typed_data';

import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class SongArtworkParams {
  const SongArtworkParams(this.songId, {this.size = 200});

  final int songId;

  /// Requested width/height in pixels.
  final int size;
}

/// Embedded cover art for a song, or null if it has none.
class GetSongArtworkUseCase {
  const GetSongArtworkUseCase(this.repository);

  final MusicLibraryRepository repository;

  Future<Uint8List?> call(SongArtworkParams params) =>
      repository.getArtwork(params.songId, size: params.size);
}
