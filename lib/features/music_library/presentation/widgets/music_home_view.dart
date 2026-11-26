import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/domain/entities/library_permission.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_event.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_sort_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_field.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_results.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_actions_scope.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_tabs.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_feedback_listener.dart';

/// The Music tab: the user's library as Songs / Albums / Artists, or the
/// right message while access is missing, the first scan runs, or nothing
/// was found. Expects a [MusicLibraryBloc] above it.
class MusicHomeView extends StatelessWidget {
  const MusicHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<LibraryCollectionsCubit>()..load()),
        BlocProvider(create: (_) => getIt<PlaylistsCubit>()),
        BlocProvider(create: (_) => getIt<LibrarySearchCubit>()),
        BlocProvider(create: (_) => SongSortCubit()),
      ],
      child: BlocListener<MusicLibraryBloc, MusicLibraryState>(
        // Albums and artists are derived from the songs; reload on change.
        listenWhen: (previous, current) => previous.songs != current.songs,
        listener: (context, _) {
          context.read<LibraryCollectionsCubit>().load();
          // Keep open search results current (e.g. after hiding a song).
          context.read<LibrarySearchCubit>().refresh();
        },
        // The library list is live, so no reload is needed after actions.
        child: SongActionsScope(
          child: PlaylistFeedbackListener(
            child: BlocBuilder<MusicLibraryBloc, MusicLibraryState>(
              builder: (context, state) => _buildForState(context, state),
            ),
          ),
        ),
      ),
    );
  }

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
        return _Library(state: state, onRefresh: () => _refresh(bloc));
    }
  }

  /// Starts a rescan and completes when it's done, for RefreshIndicator.
  static Future<void> _refresh(MusicLibraryBloc bloc) async {
    final finished = bloc.stream
        .firstWhere((s) => !s.isSyncing)
        .timeout(const Duration(minutes: 2), onTimeout: () => bloc.state);
    bloc.add(const MusicLibraryRefreshRequested());
    await finished;
  }
}

class _Library extends StatefulWidget {
  const _Library({required this.state, required this.onRefresh});

  final MusicLibraryState state;
  final RefreshCallback onRefresh;

  @override
  State<_Library> createState() => _LibraryState();
}

/// The library tabs, with a search mode. Opening, the 🔍 button grows
/// into a full-width search field while the title slides away, the tabs fold
/// up and the results fade in. Closing plays the same motion in reverse.
class _LibraryState extends State<_Library>
    with SingleTickerProviderStateMixin {
  static const Duration _openDuration = Duration(milliseconds: 600);
  static const Duration _closeDuration = Duration(milliseconds: 500);

  late final AnimationController _search = AnimationController(
    vsync: this,
    duration: _openDuration,
    reverseDuration: _closeDuration,
  )..addStatusListener((_) => setState(() {}));

  // Each part moves on its own slice of the timeline.
  late final Animation<double> _expand = CurvedAnimation(
    parent: _search,
    curve: Curves.easeInOutCubic,
  );
  late final Animation<double> _titleOut = CurvedAnimation(
    parent: _search,
    curve: const Interval(0, 0.45, curve: Curves.easeIn),
  );
  late final Animation<double> _tabsOut = CurvedAnimation(
    parent: _search,
    curve: const Interval(0.1, 0.7, curve: Curves.easeInOutCubic),
  );
  late final Animation<double> _resultsIn = CurvedAnimation(
    parent: _search,
    curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
  );

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// True from the moment search starts opening until it starts closing.
  bool _open = false;

  @override
  void dispose() {
    _search.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch() {
    if (_open) return;
    setState(() => _open = true);
    _search.forward();
    // Bring the keyboard up while the field expands.
    _searchFocus.requestFocus();
  }

  void _closeSearch() {
    if (!_open) return;
    _searchFocus.unfocus();
    setState(() => _open = false);
    _search.reverse().whenComplete(() {
      if (!mounted || _open) return;
      // Clear only after the motion, so results don't vanish mid-animation.
      _searchController.clear();
      context.read<LibrarySearchCubit>().clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final state = widget.state;
    final searchVisible = !_search.isDismissed;
    final tabsHidden = _search.isCompleted;

    return PopScope(
      // Back closes search first instead of leaving the screen.
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _open) _closeSearch();
      },
      child: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 16.w, 0),
              child: _SearchHeader(
                expand: _expand,
                titleOut: _titleOut,
                isOpen: _open,
                songCount: state.songs.length,
                field: LibrarySearchField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  autofocus: false,
                  onChanged: context.read<LibrarySearchCubit>().queryChanged,
                  onClose: _closeSearch,
                ),
                onOpen: _openSearch,
              ),
            ),
            verticalSpace(8),
            // Tabs fold up while searching (kept alive, just hidden).
            Visibility(
              visible: !tabsHidden,
              maintainState: true,
              maintainAnimation: true,
              child: FadeTransition(
                opacity: ReverseAnimation(_tabsOut),
                child: SizeTransition(
                  sizeFactor: ReverseAnimation(_tabsOut),
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        dividerColor: Colors.transparent,
                        indicatorColor: theme.primaryColor,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: onSurface,
                        unselectedLabelColor: onSurface.withValues(alpha: 0.5),
                        labelStyle: TextStyle(
                          fontSize: AppTextSizes.lg,
                          fontWeight: FontWeightHelper.bold,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontSize: AppTextSizes.lg,
                          fontWeight: FontWeightHelper.medium,
                        ),
                        tabs: const [
                          Tab(text: AppStrings.songs),
                          Tab(text: AppStrings.playlists),
                          Tab(text: AppStrings.albums),
                          Tab(text: AppStrings.artists),
                        ],
                      ),
                      // Thin bar while a background refresh runs.
                      SizedBox(
                        height: 2,
                        child: state.isSyncing
                            ? LinearProgressIndicator(
                                color: theme.primaryColor,
                                backgroundColor: Colors.transparent,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  // Tabs stay built underneath so their scroll positions
                  // survive a search.
                  TickerMode(
                    enabled: !tabsHidden,
                    child: Visibility(
                      visible: !tabsHidden,
                      maintainState: true,
                      child: TabBarView(
                        children: [
                          _KeepAlive(
                            child: SongsTab(
                              songs: state.songs,
                              onRefresh: widget.onRefresh,
                            ),
                          ),
                          _KeepAlive(child: const PlaylistsTab()),
                          _KeepAlive(
                            child: AlbumsTab(onRefresh: widget.onRefresh),
                          ),
                          _KeepAlive(
                            child: ArtistsTab(onRefresh: widget.onRefresh),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (searchVisible)
                    FadeTransition(
                      opacity: _resultsIn,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(_resultsIn),
                        child: ColoredBox(
                          color: theme.scaffoldBackgroundColor,
                          child: const SizedBox.expand(
                            child: LibrarySearchResultsView(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Music · N songs" with a round 🔍 button that expands leftwards into
/// [field]. The field is the pill itself: collapsed, only its search icon
/// shows; expanding reveals the hint and the ✕ button.
class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.expand,
    required this.titleOut,
    required this.isOpen,
    required this.songCount,
    required this.field,
    required this.onOpen,
  });

  final Animation<double> expand;
  final Animation<double> titleOut;
  final bool isOpen;
  final int songCount;
  final Widget field;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final collapsedSize = 48.r;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        return AnimatedBuilder(
          animation: Listenable.merge([expand, titleOut]),
          builder: (context, _) {
            final t = expand.value;
            final width = collapsedSize + (fullWidth - collapsedSize) * t;
            final collapsed = t == 0 && !isOpen;

            return Stack(
              alignment: Alignment.centerRight,
              children: [
                // Title slides left and fades as the field grows over it.
                Align(
                  alignment: Alignment.centerLeft,
                  child: IgnorePointer(
                    ignoring: titleOut.value > 0,
                    child: Opacity(
                      opacity: 1 - titleOut.value,
                      child: Transform.translate(
                        offset: Offset(-24 * titleOut.value, 0),
                        child: Padding(
                          padding: EdgeInsets.only(right: collapsedSize + 8.w),
                          child: _TitleText(songCount: songCount),
                        ),
                      ),
                    ),
                  ),
                ),
                // The pill: grows from the right edge.
                ClipRRect(
                  borderRadius: BorderRadius.circular(30.r),
                  child: SizedBox(
                    width: width,
                    height: collapsedSize,
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: fullWidth,
                      maxWidth: fullWidth,
                      child: IgnorePointer(ignoring: collapsed, child: field),
                    ),
                  ),
                ),
                // While collapsed, the whole pill is the open button.
                if (collapsed)
                  Tooltip(
                    message: AppStrings.search,
                    child: Material(
                      type: MaterialType.transparency,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onOpen,
                        child: SizedBox.square(
                          dimension: collapsedSize,
                          child: Semantics(
                            button: true,
                            label: AppStrings.search,
                            child: ColoredBox(
                              color: onSurface.withValues(alpha: 0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TitleText extends StatelessWidget {
  const _TitleText({required this.songCount});

  final int songCount;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.music,
          style: TextStyle(
            color: onSurface,
            fontSize: AppTextSizes.xxl,
            fontWeight: FontWeightHelper.bold,
          ),
        ),
        verticalSpace(2),
        Text(
          AppStrings.songsCount(songCount),
          style: TextStyle(
            color: onSurface.withValues(alpha: 0.6),
            fontSize: AppTextSizes.sm,
          ),
        ),
      ],
    );
  }
}

/// Keeps a tab page alive while another tab is shown, so switching back
/// doesn't rebuild it (no re-sorting, no cover reloads) and its scroll
/// position and state are kept. It still updates when its data changes.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
