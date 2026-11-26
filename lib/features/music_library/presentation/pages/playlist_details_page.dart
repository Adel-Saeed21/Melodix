import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/usecases/get_playlist_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/reorder_playlist_songs_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/features/music_library/presentation/widgets/collection_header.dart';
import 'package:melodix/features/music_library/presentation/widgets/collection_page_scaffold.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/action_feedback_listener.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_options_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_tile.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_list_body.dart';

/// A playlist's songs. The name, favourite state and song count stay live,
/// and the page closes itself if the playlist is deleted.
class PlaylistDetailsPage extends StatefulWidget {
  const PlaylistDetailsPage({super.key, required this.playlist});

  /// The playlist as it was when opened; live data replaces it.
  final Playlist playlist;

  @override
  State<PlaylistDetailsPage> createState() => _PlaylistDetailsPageState();
}

class _PlaylistDetailsPageState extends State<PlaylistDetailsPage> {
  bool _closing = false;

  /// The playlist was found in the live list at least once. Only then does
  /// its absence mean "deleted" (not "failed to load").
  bool _seenLive = false;

  Playlist get playlist => widget.playlist;

  /// Leaves the page once, after the playlist was deleted.
  void _closeOnce() {
    if (_closing) return;
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<PlaylistsCubit>()),
        BlocProvider(
          create: (_) => SongListCubit(
            () => getIt<GetPlaylistSongsUseCase>()(playlist.id),
            // Hold and drag songs to reorder the playlist.
            saveOrder: (songs) => getIt<ReorderPlaylistSongsUseCase>()(
              ReorderPlaylistSongsParams(playlist.id, [
                for (final song in songs) song.id,
              ]),
            ),
          )..load(),
        ),
      ],
      child: ActionFeedbackListener<PlaylistsCubit, PlaylistsState>(
        feedbackOf: (state) => state.feedback,
        child: BlocConsumer<PlaylistsCubit, PlaylistsState>(
          // Song count changed (song added / removed / hidden elsewhere):
          // reload. Not on the first load: the songs are loading already.
          listenWhen: (previous, current) =>
              !previous.isLoading &&
              previous.byId(playlist.id)?.songCount !=
                  current.byId(playlist.id)?.songCount,
          listener: (context, _) => context.read<SongListCubit>().load(),
          builder: (context, state) {
            final live = state.byId(playlist.id);
            // Deleted (here or elsewhere): leave the page.
            if (live != null) {
              _seenLive = true;
            } else if (_seenLive) {
              _closeOnce();
            }
            final current = live ?? playlist;
            return _PlaylistScaffold(playlist: current);
          },
        ),
      ),
    );
  }
}

class _PlaylistScaffold extends StatelessWidget {
  const _PlaylistScaffold({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return CollectionPageScaffold(
      actions: [PlaylistOptionsButton(playlist: playlist)],
      body: SongListBody(
        playlist: playlist,
        queueTitle: playlist.name,
        header: (songs) => _Header(
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

class _Header extends StatelessWidget {
  const _Header({required this.playlist, required this.duration});

  final Playlist playlist;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final details = playlist.songCount == 0
        ? AppStrings.songsCount(0)
        : '${AppStrings.songsCount(playlist.songCount)} · '
              '${formatDuration(duration)}';
    return CollectionHeader(
      artworkSongId: playlist.artworkSongId ?? 0,
      artwork: PlaylistCover(
        playlist: playlist,
        size: CollectionHeader.coverSize(context),
      ),
      title: playlist.name,
      subtitle: playlist.isFavorite
          ? '♥ ${AppStrings.playlist}'
          : AppStrings.playlist,
      details: details,
      placeholderIcon: Icons.queue_music_rounded,
    );
  }
}
