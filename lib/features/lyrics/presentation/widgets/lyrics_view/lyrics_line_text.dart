import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

class LyricsLineText extends StatelessWidget {
  const LyricsLineText({
    super.key,
    required this.text,
    required this.state,
    required this.accent,
    required this.ink,
    this.onTap,
  });

  final String text;
  final LyricsLineState state;
  final Color accent;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final now = state == LyricsLineState.now;
    final style = TextStyle(
      fontSize: state == LyricsLineState.plain ? 18.sp : 22.sp,
      height: 1.35,
      fontWeight: FontWeightHelper.bold,
      color: switch (state) {
        LyricsLineState.plain => ink.withValues(alpha: 0.85),
        LyricsLineState.now => accent,
        LyricsLineState.sung => ink.withValues(alpha: 0.35),
        LyricsLineState.coming => ink.withValues(alpha: 0.55),
      },
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 7.h, horizontal: 4.w),
        child: AnimatedScale(
          scale: now ? 1.04 : 1,
          // Grows from the line's own start (right in Arabic).
          alignment: Directionality.of(context) == TextDirection.rtl
              ? Alignment.centerRight
              : Alignment.centerLeft,
          duration: const Duration(milliseconds: 250),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: style,
            // An instrumental break: a quiet note.
            child: Text(text.isEmpty ? '♪' : text),
          ),
        ),
      ),
    );
  }
}

enum LyricsLineState { plain, sung, now, coming }
