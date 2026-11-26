import 'dart:ui';

import 'package:material_ui/material_ui.dart';

/// A round white icon button over the video. [filled]: on a translucent
/// disc (the main button), readable on any picture; [frosted] blurs the
/// picture behind it too.
///
/// The blur is redone for every video frame under it, so it's only for a
/// still picture (paused): while playing, the plain disc.
class VideoRoundButton extends StatelessWidget {
  const VideoRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.size,
    required this.onPressed,
    this.filled = false,
    this.frosted = false,
  });

  final IconData icon;
  final String tooltip;
  final double size;
  final VoidCallback? onPressed;
  final bool filled;
  final bool frosted;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = Material(
      color: filled ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
      shape: CircleBorder(
        side: filled
            ? BorderSide(color: Colors.white.withValues(alpha: 0.28))
            : BorderSide.none,
      ),
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
    );
    return Tooltip(
      message: tooltip,
      child: filled && frosted
          ? ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: button,
              ),
            )
          : button,
    );
  }
}
