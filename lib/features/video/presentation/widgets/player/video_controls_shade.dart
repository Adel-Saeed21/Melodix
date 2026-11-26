import 'package:material_ui/material_ui.dart';

/// Darker at the top and bottom, so white text reads on any picture.
/// Takes no touches: taps go through to the video (show / hide, double-tap).
class VideoControlsShade extends StatelessWidget {
  const VideoControlsShade({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.75),
            ],
            stops: const [0, 0.25, 0.7, 1],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
