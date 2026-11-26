import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

class HeroShuffleButton extends StatelessWidget {
  const HeroShuffleButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.shuffle_rounded, size: 18.r),
      label: Text(
        AppStrings.shufflePlay,
        style: TextStyle(
          fontSize: AppTextSizes.base,
          fontWeight: FontWeightHelper.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        shape: const StadiumBorder(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      ),
    );
  }
}
