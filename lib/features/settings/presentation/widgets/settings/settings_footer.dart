import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/widgets/melodix_mark.dart';

class SettingsFooter extends StatelessWidget {
  const SettingsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final faint = theme.colorScheme.onSurface.withValues(alpha: 0.4);
    return Padding(
      padding: EdgeInsets.only(top: 32.h, bottom: 8.h),
      child: Column(
        children: [
          MelodixMark(size: 28.r, color: theme.primaryColor),
          SizedBox(height: 8.h),
          Text(
            context.l10n.appName,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: AppTextSizes.base,
              fontWeight: FontWeightHelper.bold,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            context.l10n.settingsFooter,
            style: TextStyle(color: faint, fontSize: AppTextSizes.sm),
          ),
        ],
      ),
    );
  }
}
