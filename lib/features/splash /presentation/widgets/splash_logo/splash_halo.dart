import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_colors.dart';

class SplashHalo extends StatelessWidget {
  const SplashHalo({super.key, required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final green = AppColors.primaryColor;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            green.withValues(alpha: 0.38),
            green.withValues(alpha: 0.12),
            green.withValues(alpha: 0),
          ],
          stops: const [0.25, 0.55, 1],
        ),
      ),
    );
  }
}
