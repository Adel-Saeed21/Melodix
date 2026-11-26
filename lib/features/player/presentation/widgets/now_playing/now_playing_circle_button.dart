import 'package:material_ui/material_ui.dart';

class NowPlayingCircleButton extends StatelessWidget {
  const NowPlayingCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: onSurface.withValues(alpha: 0.08),
      ),
      icon: Icon(icon, color: onSurface),
    );
  }
}
