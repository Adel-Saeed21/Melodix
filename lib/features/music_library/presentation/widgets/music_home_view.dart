import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_event.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_sort_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/action_feedback_listener.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_actions_scope.dart';

/// The Music tab: the user's library as Songs / Albums / Artists, or the
/// right message while access is missing, the first scan runs, or nothing
/// was found. Expects a [MusicLibraryBloc] above it.
class MusicHomeView extends StatelessWidget {
  const MusicHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<LibraryCollectionsCubit>()
            ..onLibraryChanged(context.read<MusicLibraryBloc>().state.songs),
        ),
        BlocProvider(create: (_) => getIt<PlaylistsCubit>()),
        BlocProvider(
          create: (context) => getIt<LibrarySearchCubit>()
            ..updateSources(
              songs: context.read<MusicLibraryBloc>().state.songs,
            ),
        ),
        BlocProvider(create: (_) => SongSortCubit()),
      ],
      child: MultiBlocListener(
        listeners: [
          // Albums / artists regroup only when the catalog changed; the
          // search index follows the same data (no database reads).
          BlocListener<MusicLibraryBloc, MusicLibraryState>(
            listenWhen: (previous, current) =>
                !identical(previous.songs, current.songs),
            listener: (context, state) {
              context.read<LibraryCollectionsCubit>().onLibraryChanged(
                state.songs,
              );
              context.read<LibrarySearchCubit>().updateSources(
                songs: state.songs,
              );
            },
          ),
          BlocListener<LibraryCollectionsCubit, LibraryCollectionsState>(
            listenWhen: (previous, current) =>
                !identical(previous.albums, current.albums) ||
                !identical(previous.artists, current.artists),
            listener: (context, state) => context
                .read<LibrarySearchCubit>()
                .updateSources(albums: state.albums, artists: state.artists),
          ),
          BlocListener<PlaylistsCubit, PlaylistsState>(
            listenWhen: (previous, current) =>
                !identical(previous.playlists, current.playlists),
            listener: (context, state) => context
                .read<LibrarySearchCubit>()
                .updateSources(playlists: state.playlists),
          ),
        ],
        // The library list is live, so no reload is needed after actions.
        child: SongActionsScope(
          child: ActionFeedbackListener<PlaylistsCubit, PlaylistsState>(
            feedbackOf: (state) => state.feedback,
            child: BlocBuilder<MusicLibraryBloc, MusicLibraryState>(
              // Scan progress alone doesn't rebuild the screen: the Scan
              // card follows it on its own.
              buildWhen: _screenChanged,
              builder: (context, state) => _buildForState(context, state),
            ),
          ),
        ),
      ),
    );
  }

  /// Whether [current] changes what this screen shows (beyond the Scan
  /// card): the status, the songs, access, the error, or (with no songs
  /// yet) whether a scan is running.
  static bool _screenChanged(
    MusicLibraryState previous,
    MusicLibraryState current,
  ) =>
      previous.status != current.status ||
      !identical(previous.songs, current.songs) ||
      previous.permission != current.permission ||
      previous.errorMessage != current.errorMessage ||
      (current.songs.isEmpty && previous.isSyncing != current.isSyncing);

  Widget _buildForState(BuildContext context, MusicLibraryState state) {
    final bloc = context.read<MusicLibraryBloc>();

    switch (state.status) {
      case MusicLibraryStatus.initial:
        return const Center(child: CircularProgressIndicator());

      case MusicLibraryStatus.permissionRequired:
        final blocked = state.permission == LibraryPermission.permanentlyDenied;
        return LibraryStatusView(
          icon: Icons.library_music_rounded,
          title: AppStrings.allowMusicAccessTitle,
          message: blocked
              ? AppStrings.musicAccessBlockedSubtitle
              : AppStrings.allowMusicAccessSubtitle,
          actionLabel: blocked
              ? AppStrings.openSettings
              : AppStrings.allowAccess,
          onAction: () => bloc.add(
            blocked
                ? const MusicLibraryOpenSettingsRequested()
                : const MusicLibraryPermissionRequested(),
          ),
        );

      case MusicLibraryStatus.scanning:
        return const LibraryStatusView(
          showProgress: true,
          title: AppStrings.scanningLibraryTitle,
          message: AppStrings.scanningLibrarySubtitle,
        );

      case MusicLibraryStatus.failure:
        return LibraryStatusView(
          icon: Icons.error_outline_rounded,
          title: AppStrings.libraryErrorTitle,
          message: state.errorMessage ?? '',
          actionLabel: AppStrings.tryAgain,
          onAction: () => bloc.add(const MusicLibraryRefreshRequested()),
        );

      case MusicLibraryStatus.ready:
        if (state.songs.isEmpty && !state.isSyncing) {
          return LibraryStatusView(
            icon: Icons.music_off_rounded,
            title: AppStrings.noMusicTitle,
            message: AppStrings.noMusicSubtitle,
            actionLabel: AppStrings.tryAgain,
            onAction: () => bloc.add(const MusicLibraryRefreshRequested()),
          );
        }
        return LibraryView(state: state, onScan: () => _scan(bloc));
    }
  }

  /// Starts a scan (changes only) and completes when it's done, for the
  /// Scan button.
  static Future<void> _scan(MusicLibraryBloc bloc) async {
    final finished = bloc.stream
        // If the library closes first, there's nothing left to wait for.
        .firstWhere((s) => !s.isSyncing, orElse: () => bloc.state)
        .timeout(const Duration(minutes: 2), onTimeout: () => bloc.state);
    bloc.add(const MusicLibraryRefreshRequested());
    await finished;
  }
}
