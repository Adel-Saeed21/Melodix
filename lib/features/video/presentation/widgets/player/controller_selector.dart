import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

/// Rebuilds [builder] only when [select] of the player's value changes.
///
/// The player reports its position several times a second; a play button
/// built with this ignores those and redraws only on play / pause.
class ControllerSelector<T> extends StatefulWidget {
  const ControllerSelector({
    super.key,
    required this.controller,
    required this.select,
    required this.builder,
  });

  final VideoPlayerController controller;
  final T Function(VideoPlayerValue value) select;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<ControllerSelector<T>> createState() => _ControllerSelectorState<T>();
}

class _ControllerSelectorState<T> extends State<ControllerSelector<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.select(widget.controller.value);
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(ControllerSelector<T> old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
    _value = widget.select(widget.controller.value);
  }

  void _changed() {
    final value = widget.select(widget.controller.value);
    if (value != _value) setState(() => _value = value);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}
