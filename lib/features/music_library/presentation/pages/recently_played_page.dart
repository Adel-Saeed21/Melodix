import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/features/music_library/domain/usecases/clear_recently_played_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_recently_played_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/collection_page_scaffold.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_list_body.dart';
import 'package:melodix/features/music_library/presentation/widgets/recently_played/recently_played_hero.dart';

/// The songs played last, newest first (up to 50), updating as songs play.
class RecentlyPlayedPage extends StatelessWidget {
  const RecentlyPlayedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SongListCubit.live(
        getIt<WatchRecentlyPlayedUseCase>()(),
        clearAll: () => getIt<ClearRecentlyPlayedUseCase>()(const NoParams()),
      ),
      child: Builder(
        builder: (context) => CollectionPageScaffold(
          extendBehindAppBar: true,
          actions: [
            BlocBuilder<SongListCubit, SongListState>(
              buildWhen: (p, c) => p.songs.isEmpty != c.songs.isEmpty,
              builder: (context, state) => IconButton(
                tooltip: context.l10n.clearHistory,
                icon: const Icon(Icons.delete_sweep_rounded),
                onPressed: state.songs.isEmpty
                    ? null
                    : () => _clearHistory(context),
              ),
            ),
          ],
          body: SongListBody(
            queueTitle: context.l10n.recentlyPlayed,
            header: (songs) => RecentlyPlayedHero(songs: songs),
            emptyView: Padding(
              padding: EdgeInsets.only(top: 8),
              child: LibraryStatusView(
                icon: Icons.history_rounded,
                title: context.l10n.noRecentTitle,
                message: context.l10n.noRecentSubtitle,
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
        title: Text(context.l10n.clearHistory),
        content: Text(context.l10n.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              context.l10n.clear,
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await context.read<SongListCubit>().clearAll!();
    if (!context.mounted) return;
    result.fold(
      (failure) => AppSnackBar.show(
        context,
        context.l10n.failure(failure.message),
        kind: AppSnackBarKind.error,
      ),
      // The list empties itself (it's live).
      (_) => AppSnackBar.show(context, context.l10n.historyCleared),
    );
  }
}
