import 'package:material_ui/material_ui.dart';

/// A round white icon button over the video.
class VideoRoundButton extends StatelessWidget {
  const VideoRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.size,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final double size;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              size: size * 0.62,
              color: Colors.white.withValues(alpha: enabled ? 1 : 0.35),
            ),
          ),
        ),
      ),
    );
  }
}
