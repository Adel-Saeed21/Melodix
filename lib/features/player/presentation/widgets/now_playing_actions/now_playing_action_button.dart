import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

class NowPlayingActionButton extends StatelessWidget {
  const NowPlayingActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? theme.primaryColor
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 32.r,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 6.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? theme.primaryColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                  ),
                  child: Icon(icon, size: 22.r, color: color),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: AppTextSizes.xs,
                      fontWeight: active
                          ? FontWeightHelper.bold
                          : FontWeightHelper.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
