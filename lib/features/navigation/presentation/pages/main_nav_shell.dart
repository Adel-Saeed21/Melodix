import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/features/player/presentation/widgets/mini_player.dart';
import 'package:melodix/features/home_screen/presentation/pages/home_screen_page.dart';
import 'package:melodix/features/navigation/presentation/widgets/fade_through_tabs.dart';
import 'package:melodix/features/navigation/presentation/widgets/glass_nav_bar.dart';
import 'package:melodix/features/settings/presentation/pages/settings_page.dart';
import 'package:melodix/features/video/presentation/pages/video_page.dart';

/// Root screen after sign-in: hosts the Music, Video and Settings tabs.
///
/// Pages live in [FadeThroughTabs] so each tab keeps its state (scroll
/// position, loaded data) when the user switches between them, and the
/// switch fades through instead of cutting. Each is built on its first
/// visit.
class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key, this.pages = defaultPages});

  /// The Music, Video and Settings pages, in tab order.
  static const List<Widget> defaultPages = [
    HomeScreenPage(),
    VideoPage(),
    SettingsPage(),
  ];

  /// The tab pages, in [defaultPages] order. Tests may swap the heavy ones
  /// for stand-ins.
  @visibleForTesting
  final List<Widget> pages;

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  static const int _musicTab = 0;

  int _currentIndex = _musicTab;

  List<Widget> get _pages => widget.pages;

  static List<GlassNavItem> _items(AppLocalizations l10n) => [
    GlassNavItem(
      icon: Icons.library_music_outlined,
      activeIcon: Icons.library_music_rounded,
      label: l10n.music,
    ),
    GlassNavItem(
      icon: Icons.video_library_outlined,
      activeIcon: Icons.video_library_rounded,
      label: l10n.video,
    ),
    GlassNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: l10n.settings,
    ),
  ];

  /// Tabs opened so far. A tab is built the first time it's shown (so
  /// the Video tab doesn't scan the phone at launch unless it's opened),
  /// then kept.
  late final Set<int> _opened = {_currentIndex};

  /// Keeps the pages (and their state) when the phone turns.
  final GlobalKey _pagesKey = GlobalKey();

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
      _opened.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final pages = FadeThroughTabs(
      index: _currentIndex,
      children: [
        for (var i = 0; i < _pages.length; i++)
          _opened.contains(i) ? _pages[i] : const SizedBox.shrink(),
      ],
    );
    final nav = GlassNavBar(
      items: _items(context.l10n),
      currentIndex: _currentIndex,
      onTap: _onTap,
      axis: landscape ? Axis.vertical : Axis.horizontal,
    );
    return Scaffold(
      // Lets page content scroll behind the translucent bar. The Scaffold
      // adds the bar's height to the body's bottom padding, so SafeArea and
      // scroll views inside each page keep their content clear of it.
      extendBody: true,
      // Phone on its side: the nav moves to a rail on the left, so the
      // page keeps the little height there is. (Pages keep their state:
      // the same tabs, under a key, just move.)
      body: landscape
          ? Row(
              children: [
                Center(child: nav),
                Expanded(
                  // The rail already keeps clear of its edge (notch): the
                  // left one, or the right one in Arabic (the Row mirrors).
                  child: MediaQuery.removePadding(
                    context: context,
                    removeLeft: Directionality.of(context) == TextDirection.ltr,
                    removeRight:
                        Directionality.of(context) == TextDirection.rtl,
                    child: KeyedSubtree(key: _pagesKey, child: pages),
                  ),
                ),
              ],
            )
          : KeyedSubtree(key: _pagesKey, child: pages),
      // The mini player sits above the nav bar, on the Music tab only (the
      // Video and Settings tabs have nothing to do with songs). extendBody
      // gives lists bottom padding for both, so nothing is hidden behind
      // them.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slides away when leaving Music, and back (not a jump).
          AnimatedSwitcher(
            duration: GlassNavBar.animationDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
            child: _currentIndex == _musicTab
                ? MiniPlayer(
                    key: const ValueKey('mini-player'),
                    onExpand: () => context.pushNamed(Routes.nowPlaying),
                  )
                : const SizedBox(
                    key: ValueKey('no-mini-player'),
                    width: double.infinity,
                  ),
          ),
          if (!landscape) nav,
        ],
      ),
    );
  }
}
