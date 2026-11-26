import 'package:material_ui/material_ui.dart';

import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/widgets/media_image.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';

/// A song's embedded cover art, with a themed placeholder while loading or
/// when the song has none (see [MediaImage] for how it loads in lists).
class SongArtwork extends StatelessWidget {
  const SongArtwork({
    super.key,
    required this.songId,
    required this.size,
    this.circle = false,
    this.placeholderIcon = Icons.music_note_rounded,
  });

  final int songId;

  /// Logical width and height.
  final double size;
  final bool circle;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final artworks = getIt<GetSongArtworkUseCase>();
    return MediaImage(
      mediaKey: songId,
      width: size,
      height: size,
      load: (pixels) => artworks(SongArtworkParams(songId, size: pixels)),
      cached: (pixels) =>
          artworks.cached(SongArtworkParams(songId, size: pixels)),
      borderRadius: BorderRadius.circular(circle ? size : size * 0.18),
      placeholderIcon: placeholderIcon,
    );
  }
}
