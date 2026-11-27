import 'package:material_ui/material_ui.dart';

/// A green gradient tile hinting at the playlist cover.
class PlaylistCoverPreview extends StatelessWidget {
  const PlaylistCoverPreview({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [primary, primary.withValues(alpha: 0.55)],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.queue_music_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
