import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

/// A row of pills in a track, the chosen one filled with the accent
/// (skip length, speed, caption size…).
class PillChoices<T> extends StatelessWidget {
  const PillChoices({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  /// Each value and its label.
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          for (final (option, label) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: option == value,
                child: GestureDetector(
                  onTap: () => onChanged(option),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: option == value ? accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(11.r),
                      boxShadow: option == value
                          ? [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.35),
                                blurRadius: 10,
                              ),
                            ]
                          : const [],
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          color: option == value
                              ? theme.colorScheme.onPrimary
                              : onSurface.withValues(alpha: 0.75),
                          fontSize: AppTextSizes.base,
                          fontWeight: option == value
                              ? FontWeightHelper.bold
                              : FontWeightHelper.medium,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
