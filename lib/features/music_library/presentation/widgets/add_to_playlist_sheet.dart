import 'package:material_ui/material_ui.dart';

import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/add_to_playlist_sheet/add_to_playlist_sheet.dart';

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
    builder: (_) => AddToPlaylistSheet(songs: songs, cubit: cubit),
  );
  return added ?? false;
}
