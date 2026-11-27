import 'dart:math' as math;

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/presentation/widgets/gradient_hero/hero_play_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/gradient_hero/hero_shuffle_button.dart';

/// The top of the Favourites and Recently played pages: a tall [colors]
/// gradient that runs behind the app bar and fades into the page, with an
/// icon badge, the title, a details line and Play / Shuffle buttons.
///
/// [glow] adds the Favourites look: a soft halo around the badge and faint
/// [icon]s scattered across the background.
class GradientHero extends StatelessWidget {
  const GradientHero({
    super.key,
    required this.colors,
    required this.icon,
    required this.label,
    required this.title,
    required this.details,
    this.onPlay,
    this.onShuffle,
    this.glow = false,
    this.showActions = true,
  });

  final List<Color> colors;
  final IconData icon;

  /// Small line above the title.
  final String label;
  final String title;
  final String details;

  /// Null when there's nothing to play (the buttons are then disabled).
  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;
  final bool glow;

  /// False hides Play / Shuffle (e.g. when they live in a tab below).
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final badge = landscape ? 72.r : 112.r;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.first, colors.last, background],
          stops: const [0, 0.62, 1],
        ),
      ),
      child: Stack(
        // Centred even without the full-width Play / Shuffle row (the
        // column is only as wide as its text then).
        alignment: Alignment.topCenter,
        children: [
          if (glow) ..._scatteredIcons(),
          if (landscape)
            _landscapeContent(context, badge)
          else
            _portraitContent(context, badge),
        ],
      ),
    );
  }

  Widget _badge(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [
          Colors.white.withValues(alpha: 0.32),
          Colors.white.withValues(alpha: 0.08),
        ],
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.35),
        width: 1.5,
      ),
      boxShadow: [
        if (glow)
          BoxShadow(
            color: colors.first.withValues(alpha: 0.75),
            blurRadius: 48,
            spreadRadius: 6,
          ),
      ],
    ),
    child: Icon(icon, size: size * 0.48, color: Colors.white),
  );

  Widget _label() => Text(
    label.toUpperCase(),
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.75),
      fontSize: AppTextSizes.xs,
      fontWeight: FontWeightHelper.bold,
      letterSpacing: 1.6,
    ),
  );

  Widget _title({TextAlign align = TextAlign.center}) => Text(
    title,
    textAlign: align,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: Colors.white,
      fontSize: AppTextSizes.xxl,
      fontWeight: FontWeightHelper.bold,
    ),
  );

  Widget _details() => Text(
    details,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.8),
      fontSize: AppTextSizes.sm,
      fontWeight: FontWeightHelper.medium,
    ),
  );

  Widget _actions() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      HeroShuffleButton(onPressed: onShuffle),
      horizontalSpace(16),
      HeroPlayButton(onPressed: onPlay, color: colors.last),
    ],
  );

  /// Tall and centred: badge, then the words, then Play / Shuffle.
  Widget _portraitContent(BuildContext context, double badge) => Padding(
    padding: EdgeInsets.fromLTRB(
      20.w,
      // Below the status bar and the see-through app bar.
      MediaQuery.paddingOf(context).top + 4.h,
      20.w,
      24.h,
    ),
    child: Column(
      children: [
        _badge(badge),
        verticalSpace(18),
        _label(),
        verticalSpace(4),
        _title(),
        verticalSpace(4),
        _details(),
        if (showActions) ...[verticalSpace(20), _actions()],
      ],
    ),
  );

  /// Phone on its side (little height): one row, badge, words, then
  /// Play / Shuffle at the end.
  Widget _landscapeContent(BuildContext context, double badge) {
    final padding = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding.left + 24.w,
        padding.top + 4.h,
        padding.right + 24.w,
        16.h,
      ),
      child: Row(
        children: [
          _badge(badge),
          horizontalSpace(20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _label(),
                verticalSpace(2),
                _title(align: TextAlign.start),
                verticalSpace(2),
                _details(),
              ],
            ),
          ),
          if (showActions) ...[horizontalSpace(16), _actions()],
        ],
      ),
    );
  }

  /// Faint copies of the icon, at fixed spots so they never jump around.
  List<Widget> _scatteredIcons() {
    const spots = [
      (0.06, 0.16, 26.0, -0.35),
      (0.84, 0.10, 34.0, 0.30),
      (0.16, 0.52, 18.0, 0.20),
      (0.90, 0.46, 22.0, -0.25),
      (0.72, 0.70, 16.0, 0.45),
      (0.28, 0.80, 14.0, -0.15),
    ];
    return [
      for (final (x, y, size, turn) in spots)
        Positioned.fill(
          child: Align(
            alignment: Alignment(x * 2 - 1, y * 2 - 1),
            child: Transform.rotate(
              angle: turn * math.pi / 2,
              child: Icon(
                icon,
                size: size.r,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
    ];
  }
}
