import 'dart:math' as math;

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_accent.dart';
import 'package:melodix/features/settings/presentation/widgets/accent_swatches/accent_swatch.dart';

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
        AccentSwatch(
          label: context.l10n.coverColours,
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
          AccentSwatch(
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
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [
        hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor(),
        color,
      ],
    );
  }
}
