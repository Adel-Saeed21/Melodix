import 'package:melodix/core/config/theme/app_accent.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_shortcuts/scan_shortcut_card.dart';

/// Three gradient cards above the library tabs: Favourites, Recent and
/// Scan. The first two open their pages; Scan looks for changes on the
/// device (it never re-reads everything) and shows its progress.
///
/// **Progress.** The ring follows the sync's real stages (checking →
/// reading → saving, see [LibrarySyncStage]). Within a stage it moves on
/// smoothly but never past the stage's end, so it can't run ahead of the
/// work; it reaches 100% only when the scan is done, then shows ✓ for a
/// moment. Scans the app starts by itself (at launch, on return) show the
/// same progress, without a message.
class LibraryShortcuts extends StatelessWidget {
  const LibraryShortcuts({
    super.key,
    required this.favouriteCount,
    required this.isScanning,
    required this.onScan,
    this.syncStage,
    this.axis = Axis.horizontal,
  });

  /// Shown on the Favourites card.
  final int favouriteCount;

  /// A scan (any, e.g. the automatic one at startup) is running.
  final bool isScanning;

  /// How far the running scan got.
  final LibrarySyncStage? syncStage;

  /// Starts a scan; completes when it's done.
  final Future<void> Function() onScan;

  /// [Axis.vertical]: stacked compact cards (a side panel, phone sideways).
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final vertical = axis == Axis.vertical;
    final favourites = ShortcutCard(
      colors: AccentColors.favouritesGradient(Theme.of(context).primaryColor),
      icon: Icons.favorite_rounded,
      title: AppStrings.favourites,
      caption: AppStrings.songsCount(favouriteCount),
      onTap: () => context.pushNamed(Routes.favourites),
      compact: vertical,
    );
    final recent = ShortcutCard(
      colors: AppColors.recentGradient,
      icon: Icons.history_rounded,
      title: AppStrings.recent,
      caption: AppStrings.lastPlayed,
      onTap: () => context.pushNamed(Routes.recentlyPlayed),
      compact: vertical,
    );
    final scan = ScanShortcutCard(
      isScanning: isScanning,
      syncStage: syncStage,
      onScan: onScan,
      compact: vertical,
    );

    // Its own layer: the Scan card's progress never repaints the tabs and
    // songs below.
    return RepaintBoundary(
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                favourites,
                SizedBox(height: 8.r),
                recent,
                SizedBox(height: 8.r),
                scan,
              ],
            )
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              // Cards grow with large text (never overflow) and stay level.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: favourites),
                    SizedBox(width: 10.w),
                    Expanded(child: recent),
                    SizedBox(width: 10.w),
                    Expanded(child: scan),
                  ],
                ),
              ),
            ),
    );
  }
}

/// One shortcut: a rounded card filled with a diagonal [colors] gradient,
/// an icon badge, a title and a short caption. A large faded copy of the
/// icon sits in the corner for depth.
///
/// [compact]: one short row (badge beside the text), for stacking the cards
/// in a side panel when the phone is on its side.
class ShortcutCard extends StatelessWidget {
  const ShortcutCard({
    super.key,
    required this.colors,
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
    this.iconColor = Colors.white,
    this.progress,
    this.compact = false,
  });

  final List<Color> colors;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String caption;

  /// Null when the card can't be tapped (e.g. while scanning).
  final VoidCallback? onTap;

  /// 0–1: a ring around the icon filling up (repainted on its own layer
  /// as it changes). Null: no ring.
  final ValueListenable<double>? progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular((compact ? 16 : 20).r);
    final badge = 34.r;
    final texts = _texts(context);

    // Its own layer: a neighbour's changes never redraw this card's
    // gradient and blurred shadow.
    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: '$title, $caption',
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              // A soft coloured glow, pulled in so it never shows as a band.
              BoxShadow(
                color: colors.first.withValues(alpha: 0.30),
                blurRadius: 18,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
              child: InkWell(
                onTap: onTap,
                child: Stack(
                  children: [
                    Positioned(
                      right: -10.r,
                      bottom: -12.r,
                      child: Icon(
                        icon,
                        size: (compact ? 48 : 64).r,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    ConstrainedBox(
                      // The usual size; taller only if the text needs it.
                      constraints: BoxConstraints(
                        minHeight: compact ? 56.r : 96.h,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all((compact ? 10 : 12).r),
                        child: compact
                            ? Row(
                                children: [
                                  _badge(badge),
                                  SizedBox(width: 12.r),
                                  Expanded(child: texts),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _badge(badge),
                                  SizedBox(height: 10.h),
                                  texts,
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(double size) => SizedBox.square(
    dimension: size,
    child: Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
        if (progress case final progress?)
          RepaintBoundary(
            child: ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 2.5,
                strokeCap: StrokeCap.round,
                color: iconColor,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              icon,
              key: ValueKey(icon),
              // Smaller inside a ring.
              size: size * (progress == null ? 0.55 : 0.42),
              color: iconColor,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _texts(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: AppTextSizes.base,
          fontWeight: FontWeightHelper.bold,
        ),
      ),
      // A fixed box (one line at the current text size): a changing caption
      // ("Scanning… 42%") re-lays out only itself, never the row and the
      // tabs below it.
      SizedBox(
        width: double.infinity,
        height: MediaQuery.textScalerOf(context).scale(AppTextSizes.xs * 1.5),
        child: Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: AppTextSizes.xs,
            fontWeight: FontWeightHelper.medium,
          ),
        ),
      ),
    ],
  );
}
