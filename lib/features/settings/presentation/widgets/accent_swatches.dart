import 'dart:math' as math;

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_accent.dart';

/// The accent colours as glossy dots, after a rainbow "from the cover"
/// dot; the chosen one grows, glows and gets a ring and a check. Applies
/// at once.
class AccentSwatches extends StatelessWidget {
  const AccentSwatches({
    super.key,
    required this.value,
    required this.fromCover,
    required this.onChanged,
    required this.onFromCover,
  });

  final AppAccent value;

  /// The accent follows the playing song's cover.
  final bool fromCover;
  final ValueChanged<AppAccent> onChanged;
  final VoidCallback onFromCover;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.r,
      runSpacing: 12.r,
      children: [
        _Swatch(
          label: AppStrings.coverColours,
          gradient: SweepGradient(
            colors: [
              for (final a in AppAccent.values) a.color,
              AppAccent.values.first.color,
            ],
            transform: const GradientRotation(-math.pi / 2),
          ),
          ring: Theme.of(context).primaryColor,
          selected: fromCover,
          icon: Icons.auto_awesome_rounded,
          iconColor: Colors.white,
          onTap: onFromCover,
        ),
        for (final accent in AppAccent.values)
          _Swatch(
            label: accent.label,
            gradient: _gloss(accent.color),
            ring: accent.color,
            selected: !fromCover && accent == value,
            icon: Icons.check_rounded,
            iconColor: accent.onColor,
            onTap: () => onChanged(accent),
          ),
      ],
    );
  }

  static Gradient _gloss(Color color) {
    final hsl = HSLColor.fromColor(color);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor(),
        color,
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
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
