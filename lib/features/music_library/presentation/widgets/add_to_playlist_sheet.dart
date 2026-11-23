import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_dialogs.dart';

/// Lets the user pick a playlist for [songs] (one or many), or create a new
/// one with them. Returns true if the songs were added.
Future<bool> showAddToPlaylistSheet(
  BuildContext context, {
  required List<Song> songs,
  required SongActionsCubit cubit,
}) async {
  final added = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AddToPlaylistSheet(songs: songs, cubit: cubit),
  );
  return added ?? false;
}

class _AddToPlaylistSheet extends StatefulWidget {
  const _AddToPlaylistSheet({required this.songs, required this.cubit});

  final List<Song> songs;
  final SongActionsCubit cubit;

  @override
  State<_AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<_AddToPlaylistSheet> {
  late final Future<List<Playlist>> _playlists = widget.cubit.loadPlaylists();

  Future<void> _createNew() async {
    final name = await showPlaylistNameDialog(context);
    if (name == null || !mounted) return;
    final navigator = Navigator.of(context);
    final added = await widget.cubit.createPlaylistWithMany(widget.songs, name);
    navigator.pop(added);
  }

  Future<void> _add(Playlist playlist) async {
    final navigator = Navigator.of(context);
    final added = await widget.cubit.addManyToPlaylist(widget.songs, playlist);
    navigator.pop(added);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return FutureBuilder<List<Playlist>>(
      future: _playlists,
      builder: (context, snapshot) {
        final playlists = snapshot.data ?? const <Playlist>[];
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: 16.h),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
                child: Text(
                  AppStrings.addToPlaylist,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: AppTextSizes.lg,
                    fontWeight: FontWeightHelper.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.add_rounded, color: theme.primaryColor),
                title: Text(
                  AppStrings.newPlaylist,
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeightHelper.semiBold,
                  ),
                ),
                onTap: _createNew,
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (playlists.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  child: Text(
                    AppStrings.noPlaylistsYet,
                    style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                  ),
                )
              else
                for (final playlist in playlists)
                  ListTile(
                    leading: Icon(
                      Icons.queue_music_rounded,
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                    title: Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(AppStrings.songsCount(playlist.songCount)),
                    onTap: () => _add(playlist),
                  ),
            ],
          ),
        );
      },
    );
  }
}
