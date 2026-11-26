import 'package:melodix/core/models/load_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/artist_tile.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_tabs/tab_layout.dart';

class ArtistsTab extends StatelessWidget {
  const ArtistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCollectionsCubit, LibraryCollectionsState>(
      builder: (context, state) {
        if (state.status == LoadStatus.loading && state.artists.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.artists.isEmpty) {
          return const LibraryStatusView(
            icon: Icons.person_rounded,
            title: AppStrings.noArtists,
            message: AppStrings.noMusicSubtitle,
          );
        }
        return ListView.builder(
          padding: libraryListPadding(context),
          itemCount: state.artists.length,
          itemBuilder: (context, index) {
            final artist = state.artists[index];
            return ArtistTile(
              artist: artist,
              onTap: () =>
                  context.pushNamed(Routes.artistDetails, extra: artist),
            );
          },
        );
      },
    );
  }
}
