import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
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
