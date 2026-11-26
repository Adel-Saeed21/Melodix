import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';

class MediaImagePlaceholder extends StatelessWidget {
  const MediaImagePlaceholder({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.primaryColor.withValues(alpha: 0.14),
      child: LayoutBuilder(
        builder: (context, constraints) => Icon(
          icon,
          color: theme.primaryColor,
          size: (constraints.biggest.shortestSide * 0.45).clamp(16.r, 96.r),
        ),
      ),
    );
  }
}
