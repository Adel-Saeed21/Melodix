import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';

/// "Music · N songs" with a round 🔍 button that expands leftwards into
/// [field]. The field is the pill itself: collapsed, only its search icon
/// shows; expanding reveals the hint and the ✕ button.
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
              alignment: Alignment.centerRight,
              children: [
                // Title slides left and fades as the field grows over it.
                Align(
                  alignment: Alignment.centerLeft,
                  child: IgnorePointer(
                    ignoring: titleOut.value > 0,
                    child: Opacity(
                      opacity: 1 - titleOut.value,
                      child: Transform.translate(
                        offset: Offset(-24 * titleOut.value, 0),
                        child: Padding(
                          padding: EdgeInsets.only(right: collapsedSize + 8.w),
                          child: _TitleText(songCount: songCount),
                        ),
                      ),
                    ),
                  ),
                ),
                // The pill: grows from the right edge.
                ClipRRect(
                  borderRadius: BorderRadius.circular(30.r),
                  child: SizedBox(
                    width: width,
                    height: collapsedSize,
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: fullWidth,
                      maxWidth: fullWidth,
                      child: IgnorePointer(ignoring: collapsed, child: field),
                    ),
                  ),
                ),
                // While collapsed, the whole pill is the open button.
                if (collapsed)
                  Tooltip(
                    message: AppStrings.search,
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
                            label: AppStrings.search,
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

class _TitleText extends StatelessWidget {
  const _TitleText({required this.songCount});

  final int songCount;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.music,
          style: TextStyle(
            color: onSurface,
            fontSize: AppTextSizes.xxl,
            fontWeight: FontWeightHelper.bold,
          ),
        ),
        verticalSpace(2),
        Text(
          AppStrings.songsCount(songCount),
          style: TextStyle(
            color: onSurface.withValues(alpha: 0.6),
            fontSize: AppTextSizes.sm,
          ),
        ),
      ],
    );
  }
}
