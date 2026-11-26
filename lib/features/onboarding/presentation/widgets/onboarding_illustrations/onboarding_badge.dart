import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

class OnboardingBadge extends StatelessWidget {
  const OnboardingBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = filled ? Colors.white : color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
      decoration: BoxDecoration(
        color: filled ? color : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 18.r),
          SizedBox(width: 6.r),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeightHelper.bold,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
