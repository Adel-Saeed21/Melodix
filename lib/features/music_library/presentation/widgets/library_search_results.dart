import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/library_search_results.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/artist_tile.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_tile.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_options_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_tile.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';

enum _Section { songs, artists, albums, playlists }

/// Search results grouped into Songs, Artists, Albums and Playlists. Each
/// group shows a few items with "Show all" to expand.
class LibrarySearchResultsView extends StatefulWidget {
  const LibrarySearchResultsView({super.key});

  @override
  State<LibrarySearchResultsView> createState() =>
      _LibrarySearchResultsViewState();
}

class _LibrarySearchResultsViewState extends State<LibrarySearchResultsView> {
  static const _previewCounts = {
    _Section.songs: 5,
    _Section.artists: 3,
    _Section.albums: 3,
    _Section.playlists: 3,
  };

  final Set<_Section> _expanded = {};
  String _expandedForQuery = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibrarySearchCubit, LibrarySearchState>(
      builder: (context, state) {
        // A new query collapses the groups again.
        if (state.query != _expandedForQuery) {
          _expanded.clear();
          _expandedForQuery = state.query;
        }

        if (!state.hasQuery) {
          return const LibraryStatusView(
            icon: Icons.manage_search_rounded,
            title: AppStrings.searchPromptTitle,
            message: AppStrings.searchPromptSubtitle,
          );
        }
        if (state.errorMessage != null) {
          return LibraryStatusView(
            icon: Icons.error_outline_rounded,
            title: AppStrings.libraryErrorTitle,
            message: state.errorMessage!,
          );
        }
        if (state.results.isEmpty) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return LibraryStatusView(
            icon: Icons.search_off_rounded,
            title: AppStrings.noResultsFor(state.query),
            message: AppStrings.noResultsSubtitle,
          );
        }

        final rows = _buildRows(context, state.results);
        return Stack(
          children: [
            ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                top: 4.h,
                bottom: MediaQuery.paddingOf(context).bottom + 16.h,
              ),
              itemCount: rows.length,
              itemBuilder: (_, index) => rows[index],
            ),
            // Thin bar while newer results load over the current ones.
            if (state.isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildRows(BuildContext context, LibrarySearchResults results) {
    final rows = <Widget>[];

    void addSection<T>(
      _Section section,
      String title,
      List<T> items,
      Widget Function(T item) build,
    ) {
      if (items.isEmpty) return;
      final preview = _previewCounts[section]!;
      final expanded = _expanded.contains(section);
      final visible = expanded ? items : items.take(preview);
      rows.add(_SectionHeader(title: title, count: items.length));
      rows.addAll(visible.map(build));
      if (!expanded && items.length > preview) {
        rows.add(
          _ShowAllButton(
            count: items.length,
            onTap: () => setState(() => _expanded.add(section)),
          ),
        );
      }
    }

    addSection(
      _Section.songs,
      AppStrings.songs,
      results.songs,
      (song) => SongTile(
        song: song,
        trailing: SongOptionsButton(song: song),
        // Play the matching songs, starting with this one.
        onTap: () => context.read<PlayerCubit>().playSongs(
          results.songs,
          results.songs.indexOf(song),
          title: AppStrings.searchResults,
        ),
      ),
    );
    addSection(
      _Section.artists,
      AppStrings.artists,
      results.artists,
      (artist) => ArtistTile(
        artist: artist,
        onTap: () => context.pushNamed(Routes.artistDetails, extra: artist),
      ),
    );
    addSection(
      _Section.albums,
      AppStrings.albums,
      results.albums,
      (album) => _AlbumRow(
        album: album,
        onTap: () => context.pushNamed(Routes.albumDetails, extra: album),
      ),
    );
    addSection(
      _Section.playlists,
      AppStrings.playlists,
      results.playlists,
      (playlist) => PlaylistTile(
        playlist: playlist,
        onTap: () => context.pushNamed(Routes.playlistDetails, extra: playlist),
      ),
    );
    return rows;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 4.h),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: onSurface,
              fontSize: AppTextSizes.lg,
              fontWeight: FontWeightHelper.bold,
            ),
          ),
          horizontalSpace(8),
          Text(
            '$count',
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.5),
              fontSize: AppTextSizes.sm,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowAllButton extends StatelessWidget {
  const _ShowAllButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: TextButton(
          onPressed: onTap,
          child: Text(
            AppStrings.showAll(count),
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
      ),
    );
  }
}

class _AlbumRow extends StatelessWidget {
  const _AlbumRow({required this.album, required this.onTap});

  final Album album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: Row(
          children: [
            SongArtwork(
              songId: album.artworkSongId,
              size: 52.r,
              placeholderIcon: Icons.album_rounded,
            ),
            horizontalSpace(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: AppTextSizes.base,
                      fontWeight: FontWeightHelper.semiBold,
                    ),
                  ),
                  verticalSpace(3),
                  Text(
                    '${album.artist} · ${AppStrings.songsCount(album.songCount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.6),
                      fontSize: AppTextSizes.sm,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
