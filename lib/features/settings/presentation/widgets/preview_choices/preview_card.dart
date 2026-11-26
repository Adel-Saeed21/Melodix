import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

class PreviewCard extends StatelessWidget {
  const PreviewCard({
    super.key,
    required this.label,
    required this.selected,
    required this.previewHeight,
    required this.onTap,
    required this.preview,
  });

  final String label;
  final bool selected;
  final double previewHeight;
  final VoidCallback onTap;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final onSurface = theme.colorScheme.onSurface;
    final radius = BorderRadius.circular(16.r);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: selected ? 1 : 0.96,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: previewHeight,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: onSurface.withValues(alpha: 0.05),
                  border: Border.all(
                    color: selected
                        ? accent
                        : onSurface.withValues(alpha: 0.08),
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.15),
                            blurRadius: 10,
                          ),
                        ]
                      : const [],
                ),
                child: ClipRRect(borderRadius: radius, child: preview),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? accent : onSurface.withValues(alpha: 0.8),
                  fontSize: AppTextSizes.sm,
                  fontWeight: selected
                      ? FontWeightHelper.bold
                      : FontWeightHelper.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
