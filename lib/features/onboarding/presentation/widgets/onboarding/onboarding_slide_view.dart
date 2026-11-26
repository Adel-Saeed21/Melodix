import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

/// One page: its illustration above, title and text below. While swiping,
/// the illustration slides slower than the page and the text fades: a
/// little depth.
class OnboardingSlideView extends StatelessWidget {
  const OnboardingSlideView({
    super.key,
    required this.slide,
    required this.index,
    required this.position,
    required this.time,
  });

  final OnboardingSlide slide;
  final int index;
  final ValueListenable<double> position;
  final Animation<double> time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final illustration = slide.illustration(time);
    return LayoutBuilder(
      builder: (context, constraints) => ValueListenableBuilder<double>(
        valueListenable: position,
        child: illustration,
        builder: (context, page, illustration) {
          final offset = (page - index).clamp(-1.0, 1.0);
          final visible = 1 - offset.abs();
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(
              children: [
                Expanded(
                  flex: 6,
                  child: Transform.translate(
                    offset: Offset(offset * constraints.maxWidth * 0.35, 0),
                    child: Transform.scale(
                      scale: 0.85 + 0.15 * visible,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: EdgeInsets.all(40.r),
                            child: illustration,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Opacity(
                    opacity: visible.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 24 * offset.abs()),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28.sp,
                                height: 1.15,
                                fontWeight: FontWeightHelper.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              slide.body,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15.sp,
                                height: 1.5,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OnboardingSlide {
  const OnboardingSlide(this.title, this.body, this.illustration);

  final String title;
  final String body;
  final Widget Function(Animation<double> time) illustration;
}
