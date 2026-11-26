import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/widgets/melodix_mark.dart';

class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({
    super.key,
    required this.showSkip,
    required this.onSkip,
  });

  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 12.w, 0),
      child: Row(
        children: [
          MelodixMark(size: 26.r, color: theme.primaryColor),
          SizedBox(width: 10.w),
          Text(
            AppStrings.appName,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeightHelper.bold,
              color: theme.colorScheme.onSurface,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
            opacity: showSkip ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              onPressed: showSkip ? onSkip : null,
              child: Text(
                AppStrings.onboardingSkip,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeightHelper.semiBold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
