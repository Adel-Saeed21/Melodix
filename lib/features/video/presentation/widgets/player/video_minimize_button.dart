import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';

/// Leaves the full-screen player; the video carries on in the small window.
class VideoMinimizeButton extends StatelessWidget {
  const VideoMinimizeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.minimize,
      color: Colors.white,
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
    );
  }
}
