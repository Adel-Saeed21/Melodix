import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';

class LibraryTitleText extends StatelessWidget {
  const LibraryTitleText({super.key, required this.songCount});

  final int songCount;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.music,
          style: TextStyle(
            color: onSurface,
            fontSize: AppTextSizes.xxl,
            fontWeight: FontWeightHelper.bold,
          ),
        ),
        verticalSpace(2),
        Text(
          context.l10n.songsCount(songCount),
          style: TextStyle(
            color: onSurface.withValues(alpha: 0.6),
            fontSize: AppTextSizes.sm,
          ),
        ),
      ],
    );
  }
}
