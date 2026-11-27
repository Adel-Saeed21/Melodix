import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';

class SubtitleNote extends StatelessWidget {
  const SubtitleNote(this.text, {super.key, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppTextSizes.sm,
          color: error ? scheme.error : scheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
