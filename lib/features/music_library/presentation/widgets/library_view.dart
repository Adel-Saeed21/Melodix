import 'package:melodix/core/search/search_history.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_field.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_header.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_results.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_shortcuts.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_tabs/albums_tab.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_tabs/artists_tab.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_tabs/playlists_tab.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_tabs/songs_tab.dart';
import 'package:melodix/core/widgets/keep_alive_tab.dart';

/// The library tabs, with a search mode. Opening, the 🔍 button grows
/// into a full-width search field while the title slides away, the tabs fold
/// up and the results fade in. Closing plays the same motion in reverse.
class LibraryView extends StatefulWidget {
  const LibraryView({super.key, required this.state, required this.onScan});

  final MusicLibraryState state;

  /// Scans the device for changes; completes when the scan is done.
  final Future<void> Function() onScan;

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView>
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

  /// Favourites in the library (counted again only when the songs change).
  /// A recent search tapped: it goes back in the field and is searched.
  void _searchAgain(String query) {
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    context.read<LibrarySearchCubit>().queryChanged(query);
    context.read<SearchHistoryCubit>().searched(query);
  }

  int _favouriteCount(MusicLibraryState state) {
    if (!identical(state.songs, _countedFrom)) {
      _countedFrom = state.songs;
      _favourites = state.songs.where((s) => s.isFavorite).length;
    }
    return _favourites;
  }

  List<Song>? _countedFrom;
  int _favourites = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final state = widget.state;
    final searchVisible = !_search.isDismissed;
    final tabsHidden = _search.isCompleted;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final header = LibrarySearchHeader(
      expand: _expand,
      titleOut: _titleOut,
      isOpen: _open,
      songCount: state.songs.length,
      field: LibrarySearchField(
        controller: _searchController,
        focusNode: _searchFocus,
        autofocus: false,
        onChanged: context.read<LibrarySearchCubit>().queryChanged,
        onSubmitted: context.read<SearchHistoryCubit>().searched,
        onClose: _closeSearch,
      ),
      onOpen: _openSearch,
    );
    // Favourites, Recent and Scan. Only these follow the scan's progress;
    // the rest of the screen doesn't rebuild for it.
    Widget shortcuts(Axis axis) =>
        BlocSelector<
          MusicLibraryBloc,
          MusicLibraryState,
          (bool, LibrarySyncStage?)
        >(
          selector: (s) => (s.isSyncing, s.syncStage),
          builder: (context, scan) => LibraryShortcuts(
            axis: axis,
            favouriteCount: _favouriteCount(state),
            isScanning: scan.$1,
            syncStage: scan.$2,
            onScan: widget.onScan,
          ),
        );
    final tabBar = TabBar(
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
      tabs: [
        Tab(text: context.l10n.songs),
        Tab(text: context.l10n.playlists),
        Tab(text: context.l10n.albums),
        Tab(text: context.l10n.artists),
      ],
    );
    // The tabs, and search results over them. Kept under one key so turning
    // the phone moves them (state, scroll positions) instead of rebuilding.
    final content = KeyedSubtree(
      key: _contentKey,
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
                  KeepAliveTab(child: SongsTab(songs: state.songs)),
                  KeepAliveTab(child: const PlaylistsTab()),
                  KeepAliveTab(child: const AlbumsTab()),
                  KeepAliveTab(child: const ArtistsTab()),
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
                  child: SizedBox.expand(
                    child: LibrarySearchResultsView(onQuery: _searchAgain),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    Widget foldWhileSearching(Widget child) => Visibility(
      // Tabs fold up while searching (kept alive, just hidden).
      visible: !tabsHidden,
      maintainState: true,
      maintainAnimation: true,
      child: FadeTransition(
        opacity: ReverseAnimation(_tabsOut),
        child: SizeTransition(
          sizeFactor: ReverseAnimation(_tabsOut),
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
    );

    return PopScope(
      // Back closes search first instead of leaving the screen.
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _open) _closeSearch();
      },
      child: DefaultTabController(
        length: 4,
        child: landscape
            // Phone on its side: little height, so the header and the
            // cards go in a side panel and the songs get the full height.
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 280.w,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        16.w,
                        12.h,
                        8.w,
                        MediaQuery.paddingOf(context).bottom + 12.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          verticalSpace(12),
                          shortcuts(Axis.vertical),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        verticalSpace(8),
                        foldWhileSearching(tabBar),
                        Expanded(child: content),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      20.w,
                      16.h,
                      16.w,
                      0,
                    ),
                    child: header,
                  ),
                  verticalSpace(8),
                  foldWhileSearching(
                    Column(
                      children: [
                        shortcuts(Axis.horizontal),
                        verticalSpace(12),
                        tabBar,
                      ],
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
      ),
    );
  }

  /// Keeps the tabs' state when the phone turns (see [build]).
  final GlobalKey _contentKey = GlobalKey();
}
