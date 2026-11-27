import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/catalog_grouping.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/collection_header.dart';
import 'package:melodix/features/music_library/presentation/widgets/collection_page_scaffold.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_list_body.dart';

/// An artist's songs, live from the library (see [AlbumDetailsPage]).
class ArtistDetailsPage extends StatelessWidget {
  const ArtistDetailsPage({super.key, required this.artist});

  /// The artist as they were when opened; their live songs replace it.
  final Artist artist;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SongListCubit.live(
        context.read<MusicLibraryBloc>().librarySongs().map(
          (songs) => CatalogGrouping.artistSongs(songs, artist.name),
        ),
      ),
      child: CollectionPageScaffold(
        body: SongListBody(
          showGoToArtist: false,
          queueTitle: artist.name,
          subtitleFor: (song) => song.album,
          header: (songs) {
            final live = songs.isEmpty
                ? artist
                : CatalogGrouping.artists(songs).single;
            return CollectionHeader(
              artworkSongId: live.artworkSongId,
              title: live.name,
              subtitle: context.l10n.artist,
              details:
                  '${context.l10n.albumsCount(live.albumCount)} · '
                  '${context.l10n.songsCount(live.songCount)}',
              circle: true,
              placeholderIcon: Icons.person_rounded,
            );
          },
        ),
      ),
    );
  }
}
