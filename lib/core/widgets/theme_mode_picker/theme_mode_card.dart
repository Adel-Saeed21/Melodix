import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/widgets/theme_mode_picker/theme_mini_phone.dart';

class ThemeModeCard extends StatelessWidget {
  const ThemeModeCard({
    super.key,
    required this.icon,
    required this.label,
    required this.dark,
    required this.split,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool dark;

  /// Half dark, half light (follows the phone).
  final bool split;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.06 : 0.96,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(
                    color: selected ? accent : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 20,
                          ),
                        ]
                      : const [],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18.r),
                      child: SizedBox(
                        width: 82.r,
                        height: 150.r,
                        child: split
                            ? Row(
                                children: [
                                  Expanded(
                                    child: ClipRect(
                                      child: OverflowBox(
                                        alignment: Alignment.centerLeft,
                                        maxWidth: 82.r,
                                        child: ThemeMiniPhone(
                                          dark: true,
                                          accent: accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: ClipRect(
                                      child: OverflowBox(
                                        alignment: Alignment.centerRight,
                                        maxWidth: 82.r,
                                        child: ThemeMiniPhone(
                                          dark: false,
                                          accent: accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ThemeMiniPhone(dark: dark, accent: accent),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        right: -8.r,
                        top: -8.r,
                        child: Container(
                          padding: EdgeInsets.all(3.r),
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 16.r,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 12.r),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16.r,
                    color: selected
                        ? accent
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  SizedBox(width: 4.r),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: selected
                          ? FontWeightHelper.bold
                          : FontWeightHelper.medium,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
