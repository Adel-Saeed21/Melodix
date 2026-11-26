import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/service/audio_library_delta_source.dart';
import 'package:melodix/features/music_library/data/sync/library_sync_plan.dart';

MediaStoreCheckpoint cp(
  Map<String, int> generations, {
  String version = 'v1',
  int count = 10,
}) => MediaStoreCheckpoint(
  version: version,
  generations: generations,
  audioCount: count,
);

void main() {
  LibrarySyncPlan plan({
    bool force = false,
    MediaStoreCheckpoint? current,
    MediaStoreCheckpoint? saved,
    int savedRules = 1,
    int rules = 1,
  }) => planLibrarySync(
    force: force,
    current: current,
    saved: saved == null ? null : (checkpoint: saved, rulesVersion: savedRules),
    rulesVersion: rules,
  );

  FullScanReason? fullReason(LibrarySyncPlan p) =>
      p is FullSync ? p.reason : null;

  test('forced refresh always scans fully', () {
    final same = cp({'external_primary': 5});
    expect(
      fullReason(plan(force: true, current: same, saved: same)),
      FullScanReason.forced,
    );
  });

  test('no generations (Android 10, iOS, error) scans fully', () {
    expect(
      fullReason(plan(current: null, saved: cp({'a': 1}))),
      FullScanReason.unsupported,
    );
  });

  test('no saved checkpoint (first sync) scans fully', () {
    expect(
      fullReason(plan(current: cp({'a': 1}))),
      FullScanReason.noCheckpoint,
    );
  });

  test('a new filter rules version scans fully', () {
    final same = cp({'a': 1});
    expect(
      fullReason(plan(current: same, saved: same, savedRules: 1, rules: 2)),
      FullScanReason.rulesChanged,
    );
  });

  test('a rebuilt MediaStore (new version) scans fully', () {
    expect(
      fullReason(
        plan(
          current: cp({'a': 1}, version: 'v2'),
          saved: cp({'a': 9}, version: 'v1'),
        ),
      ),
      FullScanReason.mediaStoreRebuilt,
    );
  });

  test('identical checkpoint skips', () {
    final same = cp({'a': 3, 'b': 7});
    expect(plan(current: same, saved: cp({'a': 3, 'b': 7})), isA<SkipSync>());
  });

  test('changed generations read only what changed, per volume', () {
    final p = plan(
      current: cp({'external_primary': 12, 'sd': 7}),
      saved: cp({'external_primary': 10, 'sd': 7}),
    );
    expect(p, isA<IncrementalSync>());
    expect((p as IncrementalSync).since, {'external_primary': 10, 'sd': 7});
  });

  test('a deletion alone (count changed) is incremental', () {
    final p = plan(
      current: cp({'a': 3}, count: 9),
      saved: cp({'a': 3}, count: 10),
    );
    expect(p, isA<IncrementalSync>());
    expect((p as IncrementalSync).since, {'a': 3});
  });

  test('a newly inserted volume is read from the start', () {
    final p = plan(
      current: cp({'external_primary': 10, 'sd': 4}),
      saved: cp({'external_primary': 10}),
    ) as IncrementalSync;
    expect(p.since, {'external_primary': 10, 'sd': 0});
  });

  test('a removed volume is not queried', () {
    final p = plan(
      current: cp({'external_primary': 10}, count: 5),
      saved: cp({'external_primary': 10, 'sd': 4}, count: 8),
    ) as IncrementalSync;
    expect(p.since, {'external_primary': 10});
  });

  test('checkpoints round-trip through storage', () {
    final original = cp({'external_primary': 10, 'sd': 4}, count: 42);
    final decoded = decodeSyncCheckpoint(encodeSyncCheckpoint(original, 3))!;
    expect(decoded.checkpoint, original);
    expect(decoded.rulesVersion, 3);
    expect(decodeSyncCheckpoint('not json'), isNull);
    expect(decodeSyncCheckpoint(null), isNull);
  });
}
