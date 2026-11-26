import 'package:melodix/core/models/load_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/album_card.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_tabs/tab_layout.dart';

class AlbumsTab extends StatelessWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCollectionsCubit, LibraryCollectionsState>(
      builder: (context, state) {
        if (state.status == LoadStatus.loading && state.albums.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.albums.isEmpty) {
          return const LibraryStatusView(
            icon: Icons.album_rounded,
            title: AppStrings.noAlbums,
            message: AppStrings.noMusicSubtitle,
          );
        }
        return GridView.builder(
          padding: libraryListPadding(context)
              .add(EdgeInsets.symmetric(horizontal: 20.w)),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 0.72,
          ),
          itemCount: state.albums.length,
          itemBuilder: (context, index) {
            final album = state.albums[index];
            return AlbumCard(
              album: album,
              onTap: () => context.pushNamed(Routes.albumDetails, extra: album),
            );
          },
        );
      },
    );
  }
}
