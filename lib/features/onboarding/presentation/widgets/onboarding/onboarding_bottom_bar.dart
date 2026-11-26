import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

/// The dots (the current one stretched into a pill, following the swipe)
/// and the button: a round arrow that grows into "Start listening" on the
/// last page.
class OnboardingBottomBar extends StatelessWidget {
  const OnboardingBottomBar({
    super.key,
    required this.count,
    required this.position,
    required this.isLast,
    required this.onNext,
  });

  final int count;
  final ValueListenable<double> position;
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final onAccent = theme.colorScheme.onPrimary;
    return Padding(
      padding: EdgeInsets.fromLTRB(28.w, 8.h, 28.w, 24.h),
      child: Row(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: position,
            builder: (context, page, _) => Row(
              children: [
                for (var i = 0; i < count; i++)
                  Builder(
                    builder: (context) {
                      final near = (1 - (page - i).abs()).clamp(0.0, 1.0);
                      return Container(
                        margin: EdgeInsets.only(right: 6.w),
                        width: 8.r + 20.r * near,
                        height: 8.r,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            theme.colorScheme.onSurface.withValues(alpha: 0.25),
                            accent,
                            near,
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // Shrinks rather than overflows (large text, narrow screens).
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _nextButton(accent, onAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextButton(Color accent, Color onAccent) {
    return Semantics(
      button: true,
      label: isLast ? AppStrings.onboardingStart : AppStrings.onboardingNext,
      excludeSemantics: true,
      child: Material(
        color: accent,
        shape: const StadiumBorder(),
        elevation: 6,
        shadowColor: accent.withValues(alpha: 0.5),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onNext,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLast ? 26.w : 18.r,
                vertical: 18.r,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLast) ...[
                    Text(
                      AppStrings.onboardingStart,
                      style: TextStyle(
                        color: onAccent,
                        fontSize: 16.sp,
                        fontWeight: FontWeightHelper.bold,
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Icon(
                    isLast
                        ? Icons.play_arrow_rounded
                        : Icons.arrow_forward_rounded,
                    color: onAccent,
                    size: 24.r,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
