import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/catalog_grouping.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/features/music_library/presentation/widgets/collection_header.dart';
import 'package:melodix/features/music_library/presentation/widgets/collection_page_scaffold.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_list_body.dart';

/// An album's songs, live from the library: songs hidden, deleted or
/// added elsewhere show up here (and in the header) right away.
class AlbumDetailsPage extends StatelessWidget {
  const AlbumDetailsPage({super.key, required this.album});

  /// The album as it was when opened; its live songs replace it.
  final Album album;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SongListCubit.live(
        context.read<MusicLibraryBloc>().librarySongs().map(
          (songs) => CatalogGrouping.albumSongs(songs, album),
        ),
      ),
      child: CollectionPageScaffold(
        body: SongListBody(
          showGoToAlbum: false,
          queueTitle: album.title,
          header: (songs) {
            final live = songs.isEmpty
                ? album
                : CatalogGrouping.albums(songs).single;
            return CollectionHeader(
              artworkSongId: live.artworkSongId,
              title: live.title,
              subtitle: live.artist,
              details:
                  '${context.l10n.songsCount(live.songCount)} · '
                  '${formatDuration(live.duration)}',
            );
          },
        ),
      ),
    );
  }
}
