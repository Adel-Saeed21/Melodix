import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_tabs/tab_layout.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_dialogs.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_tile.dart';

class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({super.key});

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<PlaylistsCubit>();
    final name = await showPlaylistNameDialog(context);
    if (name != null) await cubit.create(name);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return BlocBuilder<PlaylistsCubit, PlaylistsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.playlists.isEmpty) {
          return LibraryStatusView(
            icon: Icons.queue_music_rounded,
            title: AppStrings.noPlaylistsYet,
            message: AppStrings.createPlaylistHint,
            actionLabel: AppStrings.newPlaylist,
            onAction: () => _create(context),
          );
        }
        return ListView.builder(
          padding: libraryListPadding(context),
          itemCount: state.playlists.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
                leading: Container(
                  width: 52.r,
                  height: 52.r,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(52.r * 0.18),
                  ),
                  child: Icon(Icons.add_rounded, color: primary),
                ),
                title: Text(
                  AppStrings.newPlaylist,
                  style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                ),
                onTap: () => _create(context),
              );
            }
            final playlist = state.playlists[index - 1];
            return PlaylistTile(
              playlist: playlist,
              onTap: () =>
                  context.pushNamed(Routes.playlistDetails, extra: playlist),
            );
          },
        );
      },
    );
  }
}
