import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_shortcuts.dart';

/// The Scan card and its progress (only this card rebuilds while a scan
/// runs; see [LibraryShortcuts] for how progress works).
class ScanShortcutCard extends StatefulWidget {
  const ScanShortcutCard({
    super.key,
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
  State<ScanShortcutCard> createState() => _ScanCardState();
}

class _ScanCardState extends State<ScanShortcutCard>
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
  void didUpdateWidget(ScanShortcutCard old) {
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
          ? context.l10n.libraryUpToDate
          : context.l10n.scanResult(added: added, removed: removed),
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
      title: context.l10n.scan,
      caption: idle
          ? context.l10n.findNewMusic
          : done
          ? context.l10n.scanDone
          : context.l10n.scanningPercent(_percent),
      progress: idle ? null : _ring,
      onTap: idle && !widget.isScanning ? _scan : null,
      compact: widget.compact,
    );
  }
}

enum _ScanDisplay { idle, running, finishing }
