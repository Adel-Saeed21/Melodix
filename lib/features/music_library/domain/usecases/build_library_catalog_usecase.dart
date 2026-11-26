import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/catalog_grouping.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

/// Albums and artists built from songs already in memory (no database
/// reads). See [CatalogGrouping].
class BuildLibraryCatalogUseCase {
  const BuildLibraryCatalogUseCase();

  ({List<Album> albums, List<Artist> artists}) call(List<Song> songs) => (
    albums: CatalogGrouping.albums(songs),
    artists: CatalogGrouping.artists(songs),
  );
}
