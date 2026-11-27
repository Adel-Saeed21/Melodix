import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_list_body.dart';
import 'package:melodix/features/music_library/presentation/widgets/favourites/favourite_songs_actions.dart';

class FavouriteSongsTab extends StatelessWidget {
  const FavouriteSongsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SongListBody(
      insideNestedScrollView: true,
      queueTitle: context.l10n.favourites,
      header: (songs) => songs.isEmpty
          ? const SizedBox.shrink()
          : FavouriteSongsActions(songs: songs),
      emptyView: Padding(
        padding: EdgeInsets.only(top: 8),
        child: LibraryStatusView(
          icon: Icons.favorite_border_rounded,
          title: context.l10n.noFavouritesTitle,
          message: context.l10n.noFavouritesSubtitle,
        ),
      ),
    );
  }
}
