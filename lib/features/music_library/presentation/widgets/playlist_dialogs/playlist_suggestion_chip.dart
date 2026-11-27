import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

class PlaylistSuggestionChip extends StatelessWidget {
  const PlaylistSuggestionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final onSurface = theme.colorScheme.onSurface;

    return Material(
      color: selected
          ? primary.withValues(alpha: 0.16)
          : onSurface.withValues(alpha: 0.06),
      shape: StadiumBorder(
        side: BorderSide(color: selected ? primary : Colors.transparent),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? primary : onSurface.withValues(alpha: 0.8),
              fontSize: AppTextSizes.sm,
              fontWeight: FontWeightHelper.medium,
            ),
          ),
        ),
      ),
    );
  }
}
