import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/clear_recently_played_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_recently_played_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/collection_page_scaffold.dart';
import 'package:melodix/features/music_library/presentation/widgets/gradient_hero.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_list_body.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';

/// The songs played last, newest first (up to 50), updating as songs play.
class RecentlyPlayedPage extends StatelessWidget {
  const RecentlyPlayedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SongListCubit.live(getIt<WatchRecentlyPlayedUseCase>()()),
      child: Builder(
        builder: (context) => CollectionPageScaffold(
          extendBehindAppBar: true,
          actions: [
            BlocBuilder<SongListCubit, SongListState>(
              buildWhen: (p, c) => p.songs.isEmpty != c.songs.isEmpty,
              builder: (context, state) => IconButton(
                tooltip: AppStrings.clearHistory,
                icon: const Icon(Icons.delete_sweep_rounded),
                onPressed: state.songs.isEmpty
                    ? null
                    : () => _clearHistory(context),
              ),
            ),
          ],
          body: SongListBody(
            queueTitle: AppStrings.recentlyPlayed,
            header: (songs) => _Hero(songs: songs),
            emptyView: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LibraryStatusView(
                icon: Icons.history_rounded,
                title: AppStrings.noRecentTitle,
                message: AppStrings.noRecentSubtitle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _clearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.clearHistory),
        content: const Text(AppStrings.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              AppStrings.clear,
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await getIt<ClearRecentlyPlayedUseCase>()(const NoParams());
    if (!context.mounted) return;
    result.fold(
      (failure) => AppSnackBar.show(
        context,
        failure.message,
        kind: AppSnackBarKind.error,
      ),
      // The list empties itself (it's live).
      (_) => AppSnackBar.show(context, AppStrings.historyCleared),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerCubit>();
    final hasSongs = songs.isNotEmpty;
    return GradientHero(
      colors: AppColors.recentGradient,
      icon: Icons.history_rounded,
      label: AppStrings.lastPlayed,
      title: AppStrings.recentlyPlayed,
      details: AppStrings.songsCount(songs.length),
      onPlay: hasSongs
          ? () => player.playSongs(songs, 0, title: AppStrings.recentlyPlayed)
          : null,
      onShuffle: hasSongs
          ? () => player.shufflePlay(songs, title: AppStrings.recentlyPlayed)
          : null,
    );
  }
}
