import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/widgets/glow_background.dart';

class BackdropGlow extends StatefulWidget {
  const BackdropGlow({super.key});

  @override
  State<BackdropGlow> createState() => _GlowState();
}

class _GlowState extends State<BackdropGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _time = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _time.stop();
    } else if (!_time.isAnimating) {
      unawaited(_time.repeat());
    }
  }

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      GlowBackground(time: _time, progress: const AlwaysStoppedAnimation(0));
}
