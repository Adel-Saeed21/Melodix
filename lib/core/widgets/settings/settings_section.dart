import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';

/// The accent and a hue next to it (the onboarding's glow uses the same
/// pair), for gradients.
(Color, Color) accentPair(BuildContext context) {
  final accent = Theme.of(context).primaryColor;
  final hsl = HSLColor.fromColor(accent);
  return (accent, hsl.withHue((hsl.hue + 45) % 360).toColor());
}

/// A group of settings: a small muted label above a plain card, its rows
/// split by thin lines.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.55);
    final dark = theme.brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(top: 22.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(6.w, 0, 6.w, 8.h),
            child: Row(
              children: [
                Icon(icon, size: 16.r, color: muted),
                horizontalSpace(8),
                Text(
                  title,
                  style: TextStyle(
                    color: muted,
                    fontSize: AppTextSizes.sm,
                    fontWeight: FontWeightHelper.semiBold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: dark ? AppColors.fieldDark : AppColors.fieldLight,
            borderRadius: BorderRadius.circular(18.r),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 16.w,
                      endIndent: 16.w,
                      color: onSurface.withValues(alpha: 0.06),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Title (and subtitle) with something at the end; with [below], a choice
/// laid out under the text (swatches, previews…).
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.below,
    this.onTap,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final IconData? leading;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;

  /// Drawn in red (an action that undoes choices).
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final tint = destructive ? theme.colorScheme.error : theme.primaryColor;
    final text = Row(
      children: [
        if (leading case final icon?) ...[
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Icon(icon, size: 19.r, color: tint),
          ),
          horizontalSpace(14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: destructive ? tint : onSurface,
                  fontSize: AppTextSizes.base,
                  fontWeight: FontWeightHelper.semiBold,
                ),
              ),
              if (subtitle case final subtitle?) ...[
                SizedBox(height: 2.h),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    subtitle,
                    key: ValueKey(subtitle),
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.6),
                      fontSize: AppTextSizes.sm,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
    final content = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        16.w,
        14.h,
        14.w,
        below == null ? 14.h : 16.h,
      ),
      child: below == null
          ? text
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                text,
                SizedBox(height: 14.h),
                below!,
              ],
            ),
    );
    return onTap == null ? content : InkWell(onTap: onTap, child: content);
  }
}

/// The arrow at the end of a row that opens something.
class RowChevron extends StatelessWidget {
  const RowChevron({super.key});

  @override
  Widget build(BuildContext context) => Icon(
    Icons.chevron_right_rounded,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
  );
}
