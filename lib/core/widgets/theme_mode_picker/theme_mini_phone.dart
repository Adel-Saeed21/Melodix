import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_colors.dart';

/// A tiny Melodix screen: a header, a few song rows and the music bar.
class ThemeMiniPhone extends StatelessWidget {
  const ThemeMiniPhone({super.key, required this.dark, required this.accent});

  final bool dark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final background = dark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final ink = dark ? Colors.white : const Color(0xFF1A1A1A);
    Widget line(double width, double alpha) => Container(
      width: width,
      height: 5.r,
      decoration: BoxDecoration(
        color: ink.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(3),
      ),
    );
    return Container(
      width: 82.r,
      color: background,
      padding: EdgeInsetsDirectional.fromSTEB(8.r, 12.r, 8.r, 8.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(36.r, 0.85),
          SizedBox(height: 10.r),
          for (var i = 0; i < 4; i++) ...[
            Row(
              children: [
                Container(
                  width: 14.r,
                  height: 14.r,
                  decoration: BoxDecoration(
                    color: i == 0 ? accent : ink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(width: 5.r),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    line(34.r - i * 3, 0.6),
                    SizedBox(height: 3.r),
                    line(22.r, 0.3),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.r),
          ],
          const Spacer(),
          Container(
            height: 20.r,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF242424) : Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 5.r),
            child: Row(
              children: [
                line(28.r, 0.5),
                const Spacer(),
                Icon(Icons.play_arrow_rounded, size: 12.r, color: accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
