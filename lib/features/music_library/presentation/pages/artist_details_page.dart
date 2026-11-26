import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/usecases/get_artist_songs_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/collection_header.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_list_body.dart';
import 'package:melodix/features/player/presentation/widgets/mini_player_bar.dart';

class ArtistDetailsPage extends StatelessWidget {
  const ArtistDetailsPage({super.key, required this.artist});

  final Artist artist;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SongListCubit(() => getIt<GetArtistSongsUseCase>()(artist.name))
            ..load(),
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
            showGoToArtist: false,
            queueTitle: artist.name,
            subtitleFor: (song) => song.album,
            header: CollectionHeader(
              artworkSongId: artist.artworkSongId,
              title: artist.name,
              subtitle: AppStrings.artist,
              details:
                  '${AppStrings.albumsCount(artist.albumCount)} · '
                  '${AppStrings.songsCount(artist.songCount)}',
              circle: true,
              placeholderIcon: Icons.person_rounded,
            ),
          ),
        ),
      ),
    );
  }
}
