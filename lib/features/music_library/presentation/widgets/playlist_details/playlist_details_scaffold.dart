import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/presentation/widgets/collection_page_scaffold.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_options_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_list_body.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_details/playlist_details_header.dart';

class PlaylistDetailsScaffold extends StatelessWidget {
  const PlaylistDetailsScaffold({super.key, required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return CollectionPageScaffold(
      actions: [PlaylistOptionsButton(playlist: playlist)],
      body: SongListBody(
        playlist: playlist,
        queueTitle: playlist.name,
        header: (songs) => PlaylistDetailsHeader(
          playlist: playlist,
          duration: songs.fold(
            Duration.zero,
            (sum, song) => sum + song.duration,
          ),
        ),
        emptyView: const Padding(
          padding: EdgeInsets.only(top: 24),
          child: LibraryStatusView(
            icon: Icons.library_add_rounded,
            title: AppStrings.emptyPlaylistTitle,
            message: AppStrings.emptyPlaylistSubtitle,
          ),
        ),
      ),
    );
  }
}
