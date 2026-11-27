import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

/// Whether the phone itself asks the user before the app deletes songs or
/// videos, so the app needn't ask first.
///
/// Android 11+ (API 30) always does: deletions go through a MediaStore
/// delete request, which shows the system's own confirmation. Older
/// Android deletes at once, so the app keeps its own dialog there. Unsure
/// (another platform, the version can't be read): the app asks, to be safe.
abstract final class SystemDeleteConfirmation {
  /// Android 11's API level.
  static const int _firstAsking = 30;

  static Future<bool>? _asks;

  /// Checked once, then remembered.
  static Future<bool> asks() => _asks ??= _check();

  static Future<bool> _check() async {
    if (!Platform.isAndroid) return false;
    try {
      final sdk = int.tryParse(await PhotoManager.systemVersion());
      return sdk != null && sdk >= _firstAsking;
    } catch (_) {
      return false;
    }
  }

  /// Tests: pretend the phone does ([asks] true) or doesn't ask; null goes
  /// back to checking.
  @visibleForTesting
  static void debugOverride(bool? asks) =>
      _asks = asks == null ? null : Future.value(asks);
}
