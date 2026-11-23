import 'dart:async';

import 'package:flutter/widgets.dart';

/// Exposes app lifecycle changes as a stream, so non-UI code (e.g. BLoCs)
/// can react to the app returning to the foreground without a widget.
abstract interface class AppLifecycleService {
  /// Emits each time the app comes back to the foreground.
  Stream<void> get onResumed;
}

class AppLifecycleServiceImpl implements AppLifecycleService {
  AppLifecycleServiceImpl() {
    _listener = AppLifecycleListener(onResume: () => _resumed.add(null));
  }

  late final AppLifecycleListener _listener;
  final StreamController<void> _resumed = StreamController<void>.broadcast();

  @override
  Stream<void> get onResumed => _resumed.stream;

  void dispose() {
    _listener.dispose();
    _resumed.close();
  }
}
