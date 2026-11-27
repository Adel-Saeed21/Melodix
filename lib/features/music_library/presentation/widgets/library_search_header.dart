import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_header/library_title_text.dart';

/// "Music · N songs" with a round 🔍 button that expands towards the title
/// into [field]. The field is the pill itself: collapsed, only its search
/// icon shows; expanding reveals the hint and the ✕ button.
///
/// Laid out by reading direction: in Arabic the title is on the right and
/// the pill grows from the left edge (and still shows its 🔍 collapsed).
class LibrarySearchHeader extends StatelessWidget {
  const LibrarySearchHeader({
    super.key,
    required this.expand,
    required this.titleOut,
    required this.isOpen,
    required this.songCount,
    required this.field,
    required this.onOpen,
  });

  final Animation<double> expand;
  final Animation<double> titleOut;
  final bool isOpen;
  final int songCount;
  final Widget field;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final collapsedSize = 48.r;
    // The title slides away towards its own side (left in English, right
    // in Arabic).
    final away = Directionality.of(context) == TextDirection.rtl ? 1 : -1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        return AnimatedBuilder(
          animation: Listenable.merge([expand, titleOut]),
          builder: (context, _) {
            final t = expand.value;
            final width = collapsedSize + (fullWidth - collapsedSize) * t;
            final collapsed = t == 0 && !isOpen;

            return Stack(
              alignment: AlignmentDirectional.centerEnd,
              children: [
                // Title slides away and fades as the field grows over it.
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IgnorePointer(
                    ignoring: titleOut.value > 0,
                    child: Opacity(
                      opacity: 1 - titleOut.value,
                      child: Transform.translate(
                        offset: Offset(away * 24 * titleOut.value, 0),
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            end: collapsedSize + 8.w,
                          ),
                          child: LibraryTitleText(songCount: songCount),
                        ),
                      ),
                    ),
                  ),
                ),
                // The pill: grows from the end edge (right in English).
                ClipRRect(
                  borderRadius: BorderRadius.circular(30.r),
                  child: SizedBox(
                    width: width,
                    height: collapsedSize,
                    // A window onto the field's start, where its 🔍 is
                    // (its left in English, its right in Arabic).
                    child: OverflowBox(
                      alignment: AlignmentDirectional.centerStart,
                      minWidth: fullWidth,
                      maxWidth: fullWidth,
                      child: IgnorePointer(ignoring: collapsed, child: field),
                    ),
                  ),
                ),
                // While collapsed, the whole pill is the open button.
                if (collapsed)
                  Tooltip(
                    message: context.l10n.search,
                    child: Material(
                      type: MaterialType.transparency,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onOpen,
                        child: SizedBox.square(
                          dimension: collapsedSize,
                          child: Semantics(
                            button: true,
                            label: context.l10n.search,
                            child: ColoredBox(
                              color: onSurface.withValues(alpha: 0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
