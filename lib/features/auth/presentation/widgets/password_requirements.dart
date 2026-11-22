import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/auth/domain/validators/password_policy.dart';

/// Live strength bar + checklist for [PasswordPolicy].
///
/// Listens to [controller] directly, so only this widget rebuilds while the
/// user types, not the whole form.
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.controller});

  final TextEditingController controller;

  static const Duration _duration = Duration(milliseconds: 220);

  static String _label(PasswordRule rule) {
    switch (rule) {
      case PasswordRule.minLength:
        return AppStrings.passwordRuleMinLength;
      case PasswordRule.upperAndLowercase:
        return AppStrings.passwordRuleUpperLower;
      case PasswordRule.number:
        return AppStrings.passwordRuleNumber;
      case PasswordRule.symbol:
        return AppStrings.passwordRuleSymbol;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final password = value.text;
        final rules = PasswordPolicy.rules;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StrengthBar(
                progress:
                    PasswordPolicy.satisfiedCount(password) / rules.length,
              ),
              verticalSpace(12),
              // Two requirements per row, like a 2x2 grid.
              for (var i = 0; i < rules.length; i += 2)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      for (final rule in rules.skip(i).take(2))
                        Expanded(
                          child: _RequirementItem(
                            label: _label(rule),
                            isMet: rule.isSatisfiedBy(password),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final track = theme.colorScheme.onSurface.withValues(alpha: 0.1);
    // Red when weak, the app's green once every rule is met.
    final fill = Color.lerp(
      theme.colorScheme.error,
      theme.primaryColor,
      progress,
    )!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: SizedBox(
        height: 4.h,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track)),
            AnimatedFractionallySizedBox(
              duration: PasswordRequirements._duration,
              curve: Curves.easeOut,
              widthFactor: progress,
              heightFactor: 1,
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedContainer(
                duration: PasswordRequirements._duration,
                color: fill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementItem extends StatelessWidget {
  const _RequirementItem({required this.label, required this.isMet});

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isMet
        ? theme.primaryColor
        : theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Semantics(
      label: label,
      checked: isMet,
      excludeSemantics: true,
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: PasswordRequirements._duration,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              key: ValueKey(isMet),
              size: 16.sp,
              color: color,
            ),
          ),
          horizontalSpace(8),
          Flexible(
            child: AnimatedDefaultTextStyle(
              duration: PasswordRequirements._duration,
              style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                color: color,
                fontSize: AppTextSizes.sm,
              ),
              child: Text(label, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
