import 'dart:async';

/// A value that changes over time, for repositories that publish state:
/// [watch] gives the current value, then every change. A value equal to
/// the current one is not sent again.
class LatestValue<T> {
  LatestValue(this._value);

  T _value;
  final StreamController<T> _changes = StreamController.broadcast();

  T get value => _value;

  /// Sets [next], sending it only if it differs from the current value.
  void set(T next) {
    if (next == _value) return;
    _value = next;
    if (!_changes.isClosed) _changes.add(next);
  }

  /// The current value, then every change. Subscribes at once (not after a
  /// first `yield`, as an `async*` generator would), so a change made right
  /// after listening is never lost.
  Stream<T> watch() => Stream.multi((controller) {
    controller.add(_value);
    final subscription = _changes.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  Future<void> close() => _changes.close();
}
