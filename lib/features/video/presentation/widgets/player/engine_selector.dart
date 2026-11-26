import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';

/// Rebuilds [builder] only when [select] of the player's value changes.
///
/// The player reports its position several times a second; a play button
/// built with this ignores those and redraws only on play / pause.
class EngineSelector<T> extends StatefulWidget {
  const EngineSelector({
    super.key,
    required this.engine,
    required this.select,
    required this.builder,
  });

  final VideoEngine engine;
  final T Function(VideoEngineValue value) select;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<EngineSelector<T>> createState() => _EngineSelectorState<T>();
}

class _EngineSelectorState<T> extends State<EngineSelector<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.select(widget.engine.value);
    widget.engine.addListener(_changed);
  }

  @override
  void didUpdateWidget(EngineSelector<T> old) {
    super.didUpdateWidget(old);
    if (old.engine != widget.engine) {
      old.engine.removeListener(_changed);
      widget.engine.addListener(_changed);
    }
    _value = widget.select(widget.engine.value);
  }

  void _changed() {
    final value = widget.select(widget.engine.value);
    if (value != _value) setState(() => _value = value);
  }

  @override
  void dispose() {
    widget.engine.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}
