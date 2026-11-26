import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/config/theme/app_accent.dart';

/// The home-screen icons the user can pick: the classic one, or the
/// Melodix mark in an accent colour on dark.
enum LauncherIcon {
  classic(null),
  green(AppAccent.green),
  blue(AppAccent.blue),
  purple(AppAccent.purple),
  pink(AppAccent.pink),
  red(AppAccent.red),
  orange(AppAccent.orange),
  yellow(AppAccent.yellow),
  teal(AppAccent.teal);

  const LauncherIcon(this.accent);

  /// The mark's colour (null: the classic icon).
  final AppAccent? accent;
}

/// Switches the app's home-screen icon (Android 8+; each icon is a
/// launcher entry in the manifest, one enabled at a time).
class AppIconService {
  AppIconService({MethodChannel? channel, bool? supported})
    : _channel = channel ?? const MethodChannel('melodix/app_icon'),
      isSupported =
          supported ??
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  final MethodChannel _channel;
  final bool isSupported;

  Future<LauncherIcon> current() async {
    if (!isSupported) return LauncherIcon.classic;
    try {
      final name = await _channel.invokeMethod<String>('current');
      return LauncherIcon.values.firstWhere(
        (i) => i.name == name,
        orElse: () => LauncherIcon.classic,
      );
    } catch (_) {
      return LauncherIcon.classic;
    }
  }

  /// True if the phone took the change.
  Future<bool> set(LauncherIcon icon) async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('set', {'name': icon.name}) ??
          false;
    } catch (_) {
      return false;
    }
  }
}

/// The icon on the home screen now (null until the phone answers).
class AppIconCubit extends Cubit<LauncherIcon?> {
  AppIconCubit(this._service) : super(null) {
    _service.current().then((icon) {
      if (!isClosed && state == null) emit(icon);
    });
  }

  final AppIconService _service;

  bool get isSupported => _service.isSupported;

  /// Switches the icon; false if the phone refused (the old one stays).
  Future<bool> choose(LauncherIcon icon) async {
    final before = state;
    emit(icon);
    final ok = await _service.set(icon);
    if (!ok && !isClosed) emit(before);
    return ok;
  }
}
