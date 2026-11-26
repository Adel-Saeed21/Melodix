import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';

class AccentSwatch extends StatelessWidget {
  const AccentSwatch({
    super.key,
    required this.label,
    required this.gradient,
    required this.ring,
    required this.selected,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final Gradient gradient;
  final Color ring;
  final bool selected;

  /// Shown on the dot while it's chosen ([Icons.auto_awesome_rounded] on
  /// the cover dot always).
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = 38.r;
    final alwaysIcon = icon != Icons.check_rounded;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            scale: selected ? 1.08 : 0.92,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: size,
              height: size,
              padding: EdgeInsets.all(selected ? 3.r : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? ring : Colors.transparent,
                  width: 2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: ring.withValues(alpha: 0.25),
                          blurRadius: 10,
                        ),
                      ]
                    : const [],
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradient,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: selected || alwaysIcon
                      ? Icon(
                          icon,
                          key: ValueKey(selected),
                          size: 18.r,
                          color: iconColor,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
