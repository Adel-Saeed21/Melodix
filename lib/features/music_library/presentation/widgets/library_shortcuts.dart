import 'package:melodix/core/config/theme/app_accent.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';

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
    final scan = _ScanCard(
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

/// The Scan card and its progress (only this card rebuilds while a scan
/// runs; see [LibraryShortcuts] for how progress works).
class _ScanCard extends StatefulWidget {
  const _ScanCard({
    required this.isScanning,
    required this.syncStage,
    required this.onScan,
    this.compact = false,
  });

  final bool isScanning;
  final LibrarySyncStage? syncStage;
  final Future<void> Function() onScan;
  final bool compact;

  @override
  State<_ScanCard> createState() => _ScanCardState();
}

enum _ScanDisplay { idle, running, finishing }

class _ScanCardState extends State<_ScanCard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  Timer? _backToIdle;

  _ScanDisplay _display = _ScanDisplay.idle;

  /// What the ring shows, 0–1. Changes every frame while it moves, so
  /// only the ring listens to it (nothing else rebuilds or repaints).
  final ValueNotifier<double> _ring = ValueNotifier(0);

  /// The whole percent in the caption: the cards rebuild only when this
  /// changes (at most ~100 times per scan), not on every frame.
  int _percent = 0;

  /// How long ✓ stays before the card returns to normal.
  static const Duration _doneHold = Duration(milliseconds: 1200);

  /// Close enough to a stage's end to stop animating until the next stage
  /// (no frames at all while the device works).
  static const double _settled = 0.002;

  @override
  void initState() {
    super.initState();
    // Opened mid-scan (e.g. the one at startup): show it from the start.
    if (widget.isScanning) {
      _display = _ScanDisplay.running;
      _restartTicker();
    }
  }

  @override
  void didUpdateWidget(_ScanCard old) {
    super.didUpdateWidget(old);
    // A scan the app started by itself (or this card's, confirmed).
    if (!old.isScanning && widget.isScanning) _begin();
    if (old.isScanning && !widget.isScanning) _finish();
    // A new stage: the ring has new ground to cover.
    if (old.syncStage != widget.syncStage && _display == _ScanDisplay.running) {
      _restartTicker();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _backToIdle?.cancel();
    _ring.dispose();
    super.dispose();
  }

  void _begin() {
    if (_display == _ScanDisplay.running) return;
    _backToIdle?.cancel();
    _ring.value = 0;
    _restartTicker();
    setState(() {
      _display = _ScanDisplay.running;
      _percent = 0;
    });
  }

  void _finish() {
    if (_display != _ScanDisplay.running) return;
    _restartTicker();
    setState(() => _display = _ScanDisplay.finishing);
  }

  void _restartTicker() {
    _lastTick = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  /// The part of the ring each stage fills.
  static (double, double) _rangeOf(LibrarySyncStage? stage) => switch (stage) {
    null || LibrarySyncStage.checking => (0.0, 0.12),
    LibrarySyncStage.reading => (0.12, 0.80),
    LibrarySyncStage.saving => (0.80, 0.97),
  };

  void _onTick(Duration elapsed) {
    final seconds = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    final shown = _ring.value;
    double next;
    if (_display == _ScanDisplay.running) {
      // Ease towards the stage's end without ever reaching it (also after
      // a long gap between frames, e.g. coming back to the app).
      final (start, end) = _rangeOf(widget.syncStage);
      final cap = end - (end - start) * 0.05;
      final from = math.max(shown, start);
      next = math.min(
        cap,
        from + (cap - from) * (1 - math.exp(-1.6 * seconds)),
      );
      if (cap - next < _settled) {
        next = cap;
        _ticker.stop(); // resumes on the next stage (didUpdateWidget)
      }
    } else {
      // Done: fill up quickly, then hold ✓ for a moment.
      next = math.min(1, shown + seconds * 2.5);
      if (next >= 1) {
        _ticker.stop();
        _backToIdle = Timer(_doneHold, () {
          if (mounted) setState(() => _display = _ScanDisplay.idle);
        });
      }
    }
    _ring.value = next;
    final percent = (next * 100).floor();
    // The caption (and ✓ at 100%) only when the whole number changes.
    if (percent != _percent) setState(() => _percent = percent);
  }

  Future<void> _scan() async {
    if (_display != _ScanDisplay.idle || widget.isScanning) return;
    _begin();
    try {
      await widget.onScan();
    } finally {
      if (mounted) _finish();
    }
    if (!mounted) return;
    final state = context.read<MusicLibraryBloc>().state;
    final error = state.errorMessage;
    if (error != null) {
      AppSnackBar.show(context, error, kind: AppSnackBarKind.error);
      return;
    }
    final result = state.lastSyncResult;
    final added = result?.added ?? 0;
    final removed = result?.removed ?? 0;
    AppSnackBar.show(
      context,
      added == 0 && removed == 0
          ? AppStrings.libraryUpToDate
          : AppStrings.scanResult(added: added, removed: removed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idle = _display == _ScanDisplay.idle;
    final done = _display == _ScanDisplay.finishing && _percent >= 100;
    return ShortcutCard(
      colors: AppColors.scanGradient,
      icon: done ? Icons.check_rounded : Icons.radar_rounded,
      iconColor: Theme.of(context).primaryColor,
      title: AppStrings.scan,
      caption: idle
          ? AppStrings.findNewMusic
          : done
          ? AppStrings.scanDone
          : AppStrings.scanningPercent(_percent),
      progress: idle ? null : _ring,
      onTap: idle && !widget.isScanning ? _scan : null,
      compact: widget.compact,
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
