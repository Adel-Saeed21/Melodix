import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

class SubtitleSheetTitle extends StatelessWidget {
  const SubtitleSheetTitle(this.text, {super.key, this.padded = true});

  final String text;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padded
          ? EdgeInsetsDirectional.fromSTEB(20.w, 0, 20.w, 8.h)
          : EdgeInsets.zero,
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTextSizes.lg,
          fontWeight: FontWeightHelper.bold,
        ),
      ),
    );
  }
}
