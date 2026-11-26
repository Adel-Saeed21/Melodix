import 'package:flutter_test/flutter_test.dart';

import '../../support/isar_test_db.dart';

void main() {
  test(
    'real Isar opens in tests',
    () async {
      final isar = await openTestIsar();
      expect(isar.isOpen, isTrue);
      await closeTestIsar(isar);
    },
    skip: isarLibraryPath() == null
        ? 'No Isar library for this machine'
        : false,
  );
}
