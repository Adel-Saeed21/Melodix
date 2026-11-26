import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/usecases/get_album_songs_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:melodix/features/music_library/presentation/utils/duration_format.dart';
import 'package:melodix/features/music_library/presentation/widgets/collection_header.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_list_body.dart';
import 'package:melodix/features/player/presentation/widgets/mini_player_bar.dart';

class AlbumDetailsPage extends StatelessWidget {
  const AlbumDetailsPage({super.key, required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SongListCubit(() => getIt<GetAlbumSongsUseCase>()(album))..load(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        // Keep the player controls available on this page too.
        bottomNavigationBar: const MiniPlayerBar(),
        body: SafeArea(
          top: false,
          child: SongListBody(
            showGoToAlbum: false,
            queueTitle: album.title,
            header: CollectionHeader(
              artworkSongId: album.artworkSongId,
              title: album.title,
              subtitle: album.artist,
              details:
                  '${AppStrings.songsCount(album.songCount)} · '
                  '${formatDuration(album.duration)}',
            ),
          ),
        ),
      ),
    );
  }
}
