import 'package:material_ui/material_ui.dart';

import 'package:melodix/features/navigation/presentation/widgets/glass_nav_bar/glass_bar.dart';

/// A single destination shown in [GlassNavBar].
class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating, frosted-glass navigation: a bar along the bottom, or (with
/// [axis] vertical, for a phone on its side) a rail down the left edge,
/// which leaves the little height there is to the page.
///
/// Colors come from the active [ThemeData], so the bar follows light/dark
/// mode changes automatically. It hides itself while the software keyboard
/// is open and comes back when the keyboard closes.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.axis = Axis.horizontal,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Axis axis;

  static const Duration animationDuration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    // Only this widget depends on the keyboard inset, so opening the keyboard
    // does not rebuild the pages behind the bar.
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AnimatedSwitcher(
      duration: animationDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axis: axis == Axis.vertical ? Axis.horizontal : Axis.vertical,
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
      child: isKeyboardOpen
          ? const SizedBox.shrink(key: ValueKey('nav-hidden'))
          : RepaintBoundary(
              key: const ValueKey('nav-visible'),
              // Own layer: page animations (tab indicator, progress bars)
              // don't repaint the nav bar. Its blur still updates as the
              // content behind it changes.
              child: GlassBar(
                items: items,
                currentIndex: currentIndex,
                onTap: onTap,
                vertical: axis == Axis.vertical,
              ),
            ),
    );
  }
}
