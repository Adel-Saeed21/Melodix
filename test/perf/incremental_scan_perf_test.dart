import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/database/music_local_storage.dart';

import '../support/fake_media_store.dart';
import '../support/sync_repository_factory.dart';
import '../support/isar_test_db.dart';

/// Full vs incremental sync after 10 changed files, with the real repository
/// and real Isar (on this machine, not a phone). The device side is
/// simulated, so MediaStore's own query time isn't included; on a phone the
/// full scan additionally reads every row's columns through the platform
/// channel, which only widens the gap.
void main() {
  final skip = isarLibraryPath() == null ? 'No Isar library' : false;

  for (final size in [1000, 5000, 10000]) {
    test(
      'library of $size songs, 10 changes',
      () async {
        final fullMs = <int>[];
        final deltaMs = <int>[];
        var fullRows = 0;
        var deltaRows = 0;

        for (var run = 0; run < 3; run++) {
          final isar = await openTestIsar();
          final device = FakeMediaStore();
          final ids = [
            for (var i = 0; i < size; i++) device.add(title: 'Track $i'),
          ];
          final repo = buildSyncRepository(
            device: device,
            storage: MusicLocalStorageImpl(isar),
          );
          await repo.syncLibrary(); // initial full scan + checkpoint

          void change(int round) {
            for (var i = 0; i < 5; i++) {
              device.modify(ids[i * 7 + round], title: 'Changed $round-$i');
            }
            for (var i = 0; i < 5; i++) {
              device.add(title: 'New $round-$i');
            }
          }

          // Full scan of the changed library.
          change(1);
          device.rowsTransferred = 0;
          var sw = Stopwatch()..start();
          final full = await repo.syncLibrary(force: true);
          sw.stop();
          expect(full.isRight(), isTrue);
          fullMs.add(sw.elapsedMilliseconds);
          fullRows = device.rowsTransferred;

          // Incremental sync of the same amount of change.
          change(2);
          device.rowsTransferred = 0;
          sw = Stopwatch()..start();
          final delta = await repo.syncLibrary();
          sw.stop();
          expect(
            delta.getOrElse(() => throw StateError('failed')).incremental,
            isTrue,
          );
          deltaMs.add(sw.elapsedMilliseconds);
          deltaRows = device.rowsTransferred;

          await closeTestIsar(isar);
        }

        int median(List<int> v) => (v..sort())[v.length ~/ 2];
        // ignore: avoid_print
        print(
          'PERF $size songs, 10 changes: '
          'full ${median(fullMs)} ms / $fullRows rows read | '
          'incremental ${median(deltaMs)} ms / $deltaRows rows read',
        );
        expect(deltaRows, 10); // only the changed files
        expect(fullRows, greaterThanOrEqualTo(size));
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }
}
