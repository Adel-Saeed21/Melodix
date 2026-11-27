import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/l10n/l10n.dart';

/// Starts dragging immediately when touched (long-press works anywhere on
/// the row too).
class SongDragHandle extends StatelessWidget {
  const SongDragHandle({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: Tooltip(
        message: context.l10n.dragToReorder,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
          child: Icon(
            Icons.drag_indicator_rounded,
            size: 20.r,
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
