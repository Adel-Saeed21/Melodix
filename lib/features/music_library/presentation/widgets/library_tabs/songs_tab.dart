import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/song_selection_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_tabs/songs_tab/songs_tab_body.dart';

class SongsTab extends StatelessWidget {
  const SongsTab({super.key, required this.songs});

  final List<Song> songs;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SongSelectionCubit(),
      child: SongsTabBody(songs: songs),
    );
  }
}
