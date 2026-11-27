import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';

/// A caption, centred near the bottom, in the style chosen in Settings:
/// size, colour, and a soft dark box or an outline around the letters.
class SubtitleText extends StatelessWidget {
  const SubtitleText({super.key, required this.text, this.style, this.padding});

  final String text;

  /// The style to draw in (default: the one chosen in Settings). Settings
  /// passes its own for the preview.
  final UiPreferences? style;

  /// Around the caption (default: clear of the player's seek bar).
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final preferences = style ?? UiPreferencesScope.of(context);
    final color = switch (preferences.subtitleColor) {
      SubtitleColor.white => Colors.white,
      SubtitleColor.yellow => const Color(0xffFFE14D),
      SubtitleColor.accent => Theme.of(context).primaryColor,
    };
    final outline = preferences.subtitleLook == SubtitleLook.outline;
    final size = AppTextSizes.lg * preferences.subtitleSize.scale;
    final words = Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: outline ? FontWeightHelper.bold : FontWeightHelper.medium,
        height: 1.3,
        shadows: outline
            ? const [
                // An outline all round, then a soft shadow: readable on
                // any picture, without a box.
                Shadow(offset: Offset(1.2, 1.2)),
                Shadow(offset: Offset(-1.2, 1.2)),
                Shadow(offset: Offset(1.2, -1.2)),
                Shadow(offset: Offset(-1.2, -1.2)),
                Shadow(blurRadius: 6, color: Colors.black87),
              ]
            : null,
      ),
    );
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        // Clear of the seek bar and buttons.
        padding: padding ?? EdgeInsets.fromLTRB(24.w, 0, 24.w, 96.h),
        child: outline
            ? words
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  child: words,
                ),
              ),
      ),
    );
  }
}
