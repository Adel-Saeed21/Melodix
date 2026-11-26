import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';

class HeroPlayButton extends StatelessWidget {
  const HeroPlayButton({
    super.key,
    required this.onPressed,
    required this.color,
  });

  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = 58.r;
    return Tooltip(
      message: AppStrings.playAll,
      child: Material(
        color: onPressed == null
            ? Colors.white.withValues(alpha: 0.4)
            : Colors.white,
        shape: const CircleBorder(),
        elevation: onPressed == null ? 0 : 6,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              Icons.play_arrow_rounded,
              size: size * 0.6,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
