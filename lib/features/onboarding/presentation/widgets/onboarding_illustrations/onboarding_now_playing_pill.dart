import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/onboarding/presentation/widgets/onboarding_illustrations.dart';

class OnboardingNowPlayingPill extends StatelessWidget {
  const OnboardingNowPlayingPill({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    return Container(
      width: 200.r,
      padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 10.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30.r,
            height: 30.r,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.5)],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(width: 10.r),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                onboardingLine(context, 0.8),
                SizedBox(height: 6.r),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    color: accent,
                    backgroundColor: accent.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.r),
          Icon(Icons.pause_rounded, color: accent, size: 22.r),
        ],
      ),
    );
  }
}
