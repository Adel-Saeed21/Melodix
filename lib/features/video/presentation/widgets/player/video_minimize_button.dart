import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';

/// Leaves the full-screen player; the video carries on in the small window.
class VideoMinimizeButton extends StatelessWidget {
  const VideoMinimizeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppStrings.minimize,
      color: Colors.white,
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
    );
  }
}
