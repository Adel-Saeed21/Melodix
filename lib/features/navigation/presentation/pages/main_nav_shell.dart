import 'package:material_ui/material_ui.dart';

import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/features/home_screen/presentation/pages/home_screen_page.dart';
import 'package:melodix/features/navigation/presentation/widgets/glass_nav_bar.dart';
import 'package:melodix/features/settings/presentation/pages/settings_page.dart';
import 'package:melodix/features/video/presentation/pages/video_page.dart';

/// Root screen after sign-in: hosts the Music, Video and Settings tabs.
///
/// Pages live in an [IndexedStack] so each tab keeps its state (scroll
/// position, loaded data) when the user switches between them.
class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  /// Music is the default destination.
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    HomeScreenPage(),
    VideoPage(),
    SettingsPage(),
  ];

  static const List<GlassNavItem> _items = [
    GlassNavItem(
      icon: Icons.library_music_outlined,
      activeIcon: Icons.library_music_rounded,
      label: AppStrings.music,
    ),
    GlassNavItem(
      icon: Icons.video_library_outlined,
      activeIcon: Icons.video_library_rounded,
      label: AppStrings.video,
    ),
    GlassNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: AppStrings.settings,
    ),
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Lets page content scroll behind the translucent bar. The Scaffold
      // adds the bar's height to the body's bottom padding, so SafeArea and
      // scroll views inside each page keep their content clear of it.
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: GlassNavBar(
        items: _items,
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
