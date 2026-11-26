/// Runs operations one at a time, in the order they were asked for: an
/// operation never starts before the previous one has finished (even if it
/// failed).
class SerialRunner {
  SerialRunner({this.onIdle});

  /// Called each time the last queued operation finishes.
  final void Function()? onIdle;

  Future<void> _tail = Future.value();
  int _running = 0;

  /// An operation is running (or queued).
  bool get isBusy => _running > 0;

  /// Runs [operation] after every earlier one; completes with its result.
  Future<T?> run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) async {
      _running++;
      try {
        return await operation();
      } finally {
        _running--;
        if (_running == 0) onIdle?.call();
      }
    });
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }
}
