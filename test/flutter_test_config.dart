import 'dart:async';

import 'support/l10n_support.dart';

/// Runs before every test file: the app's texts are read in English, as
/// the tests expect, even for widgets shown without the app around them.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  useLanguage('en');
  await testMain();
}
