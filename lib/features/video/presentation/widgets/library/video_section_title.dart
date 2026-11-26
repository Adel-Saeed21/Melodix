import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

class VideoSectionTitle extends StatelessWidget {
  const VideoSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 4.h),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: AppTextSizes.lg,
          fontWeight: FontWeightHelper.bold,
        ),
      ),
    );
  }
}
