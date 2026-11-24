/// Runs at most one task at a time; callers arriving while it runs share
/// its result instead of starting another ("single flight").
class SingleFlight<T> {
  Future<T>? _running;

  /// The task currently running, if any.
  Future<T>? get running => _running;

  /// Joins the running task, or starts [task] if none is running.
  Future<T> run(Future<T> Function() task) =>
      _running ??= task().whenComplete(() => _running = null);

  /// Waits for the running task (if any), then starts [task]: for callers
  /// that need a fresh run of their own (e.g. pull-to-refresh).
  Future<T> runAfterCurrent(Future<T> Function() task) async {
    final current = _running;
    if (current != null) await current;
    return run(task);
  }
}
