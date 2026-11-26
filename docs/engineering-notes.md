# Melodix — Engineering Notes: Issues, Fixes and What to Study

Personal reference for the problems found in the music library and player,
how each was fixed, where the code lives, and what to read to understand the
ideas behind the fixes.

> Measurements in this file come from `flutter test` on a desktop machine
> (debug VM) with a simulated native audio side. Absolute times on a phone
> will differ; the *relative* improvements are what matter. Items marked
> **Device check** have not been verified on Android yet.

---

## Contents

1. [Data safety: MediaStore sync could wipe the library](#1-data-safety-mediastore-sync-could-wipe-the-library)
2. [on_audio_query quirks](#2-on_audio_query-quirks)
3. [Architecture: SOLID and design patterns](#3-architecture-solid-and-design-patterns)
4. [Library performance: reloading 10,000 songs on every play](#4-library-performance-reloading-10000-songs-on-every-play)
5. [Albums and artists read the database twice](#5-albums-and-artists-read-the-database-twice)
6. [Tap-to-play lag: 10,000 AudioSources](#6-tap-to-play-lag-10000-audiosources)
7. [Wrong-song flash after a tap](#7-wrong-song-flash-after-a-tap)
8. [Earlier fixes worth remembering](#8-earlier-fixes-worth-remembering)
9. [Testing techniques used](#9-testing-techniques-used)
10. [Open items and device checks](#10-open-items-and-device-checks)
11. [Study plan and resources](#11-study-plan-and-resources)

---

## 1. Data safety: MediaStore sync could wipe the library

### The core mistake

**An unknown or failed result was treated as "the library is empty".** When
the sync then compared "empty" with the saved library, it concluded the user
had deleted everything and removed all songs, playlist entries and recents.

### Issues and fixes

| # | Problem | Root cause | Fix |
|---|---|---|---|
| 1.1 | Without permission, the library was wiped | On Android 11+, a MediaStore query without read permission returns only the app's own media (an **empty** list), not an error | The repository checks permission first with `audioStatus()` (no dialog). No permission → `PermissionFailure`, storage untouched. The native side also checks `READ_MEDIA_AUDIO` (13+) / `READ_EXTERNAL_STORAGE` (≤12) itself |
| 1.2 | A failed ids query deleted every song | `ContentResolver.query()` can return `null`; the code turned `null` into "no ids" | `queryOrFail()`: a null cursor throws `query_failed`. Extra guard: no ids while MediaStore counts rows → failure |
| 1.3 | One unreadable volume (SD card) was skipped silently | A null cursor for one volume was ignored, and the checkpoint advanced past its changes | Any failing volume fails the whole call. No partial results |
| 1.4 | Full scan could return an empty list on failure | on_audio_query loops `while (cursor != null && …)`, so a failed query looks empty | On Android, full scans use our own native `audioFullScan` (typed errors). Elsewhere, an empty answer can't wipe a non-empty library unless MediaStore confirms 0 songs |
| 1.5 | All errors looked the same; errors were swallowed | One error code; `catch (_)` returned `null`; failed incremental queries silently fell back to a full scan | Typed errors: `permission_denied` → `MediaPermissionException`, everything else → `MediaQueryException`. No fallback on errors. Failures are logged (`melodix.library_sync`) |
| 1.6 | Background sync could show a permission dialog | `getAllSongs()` called `requestAudio()` | It now calls `audioStatus()`; only the UI asks for permission |

### Rules to remember

- **Fail safe:** unknown ≠ empty. Only an answer where *every* query succeeded
  may delete anything.
- **Atomic writes:** song updates, deletions, playlist/recents cleanup and the
  checkpoint are saved in **one Isar transaction**.
- **Checkpoint last:** the sync checkpoint moves only when the save succeeds,
  and it is read *before* the rows, so changes made during a sync are picked
  up next time.

### Where

- `android/app/src/main/kotlin/com/example/spotify/MainActivity.kt`
- `lib/core/service/audio_library_delta_source.dart`
- `lib/core/errors/exceptions.dart` (`MediaQueryException`)
- `lib/features/music_library/data/repositories/library_sync_repository_impl.dart`
- `lib/features/music_library/data/sync/full_library_scan.dart`
- `lib/features/music_library/data/sync/incremental_library_scan.dart`
- Tests: `test/features/music_library/data/sync_data_safety_test.dart`
  (8 audit scenarios + defence-in-depth), `test/core/service/media_store_delta_source_test.dart`

### Learn more

- Android — Access media files from shared storage:
  https://developer.android.com/training/data-storage/shared/media
- Android 13 granular media permissions:
  https://developer.android.com/about/versions/13/behavior-changes-13#granular-media-permissions
- `MediaStore` reference (`getVersion`, `getGeneration`, `GENERATION_MODIFIED`):
  https://developer.android.com/reference/android/provider/MediaStore
- `ContentResolver.query` (can return null):
  https://developer.android.com/reference/android/content/ContentResolver
- Flutter platform channels (MethodChannel, error codes):
  https://docs.flutter.dev/platform-integration/platform-channels
- Book: *Release It!* (Michael Nygard) — failure modes, fail-safe design.
- Book: *Designing Data-Intensive Applications* (Martin Kleppmann) — chapter on
  transactions and atomicity.

---

## 2. on_audio_query quirks

| Problem | Explanation | Fix |
|---|---|---|
| **Double reply** when permission is missing (can crash: "Reply already submitted") | The plugin calls `result.error(...)` and then still runs the query, which answers again | Never call on_audio_query without permission: `MusicServiceImpl` checks `audioStatus()` first (cached 5 s for artwork). `MissingPermissions` maps to `MediaPermissionException` |
| Does it need `READ_MEDIA_IMAGES`? | **No.** Its `permissionStatus()` uses `return` inside the inline lambda `permissions.all { return … }`. In Kotlin that is a **non-local return**: it returns from the whole function after checking only the first permission | No permission added |
| Failed artwork cached forever | The repository's LRU cached `null` on errors | Errors are not cached, so covers appear after access is granted |

### Learn more

- Kotlin inline functions and non-local returns (explains the quirk):
  https://kotlinlang.org/docs/inline-functions.html#non-local-returns
- on_audio_query package: https://pub.dev/packages/on_audio_query

---

## 3. Architecture: SOLID and design patterns

### Problem

`MusicLibraryRepository` had ~30 methods (permission, sync, songs, albums,
playlists, artwork) and one 495-line implementation. Hard to read, test and
trace.

### Fix

| Principle / pattern           | Applied as                                                                                                                                                                              |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **S** — Single Responsibility | One class per concern: `LibrarySyncRepositoryImpl`, `SongRepositoryImpl`, `CatalogRepositoryImpl`, `PlaylistRepositoryImpl`, `ArtworkRepositoryImpl`, `LibraryPermissionRepositoryImpl` |
| **I** — Interface Segregation | Six small domain interfaces; each use case depends only on the one it needs                                                                                                             |
| **D** — Dependency Inversion  | Use cases depend on interfaces; concrete classes are wired only in `get_it.dart`                                                                                                        |
| **O** — Open/Closed (partly)  | New sync strategies can be added as classes; the plan `switch` still needs a new case                                                                                                   |
| **Strategy**                  | `FullLibraryScan`, `IncrementalLibraryScan`                                                                                                                                             |
| **Mediator / Coordinator**    | `LibrarySyncRepositoryImpl` runs: permission → checkpoint → plan → strategy → error mapping                                                                                             |
| **Repository**                | Domain interfaces hide Isar, MediaStore and plugins                                                                                                                                     |
| **Single Flight**             | `SingleFlight` — concurrent syncs share one run (`lib/core/utils/single_flight.dart`)                                                                                                   |
| **LRU Cache**                 | `LruCache` for artwork (`lib/core/utils/lru_cache.dart`)                                                                                                                                |
| **Data Mapper**               | `SongMapper`, `PlaylistMapper`                                                                                                                                                          |
| **Template-style wrapper**    | `guardRepositoryCall` — the try/catch → `Failure` step written once                                                                                                                     |
| **Sealed classes**            | `LibrarySyncPlan` (`SkipSync` / `IncrementalSync` / `FullSync`), `LibraryUpdate`                                                                                                        |

### Learn more

- *The Clean Architecture* (Robert C. Martin):
  https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- Book: *Clean Architecture* and *Agile Software Development: Principles,
  Patterns, and Practices* (Robert C. Martin) — SOLID in depth.
- Refactoring.Guru — design patterns with examples:
  - Strategy: https://refactoring.guru/design-patterns/strategy
  - Mediator: https://refactoring.guru/design-patterns/mediator
  - Template Method: https://refactoring.guru/design-patterns/template-method
- Single flight (Go's original version of the idea):
  https://pkg.go.dev/golang.org/x/sync/singleflight
- LRU cache: https://en.wikipedia.org/wiki/Cache_replacement_policies
- Dart sealed classes and pattern matching:
  https://dart.dev/language/class-modifiers#sealed and
  https://dart.dev/language/patterns
- Bloc library (Bloc/Cubit, `buildWhen`, `BlocSelector`): https://bloclibrary.dev

---

## 4. Library performance: reloading 10,000 songs on every play

### Problem

Every play count, favourite or hide **re-read and re-mapped the whole
library**. The player writes a play count each time a song starts, so this
happened at exactly the moment the UI animates.

### Root cause

`watchAllSongs()` used an Isar query watcher. Isar re-runs the whole query on
any write to the collection → 10,000 rows read → 10,000 `Song` objects → bloc
emission → listeners re-check sorting, search and albums.

Note: the player calls `MusicLocalStorage.recordPlay` **directly** (not
through a use case), so the change signal had to come from the storage layer.

### Fix — in-memory patches

- The storage emits typed updates **after each write commits**
  (`lib/core/database/song_library_update.dart`):
  - `SongLibraryLoaded` — full list (first load, sync with changes, unhide);
  - `SongLibrarySongsChanged` — only the changed rows (play, favourite);
  - `SongLibrarySongsRemoved` — only ids (hide, delete).
- Updates are delivered **in commit order** through a queue, and back-to-back
  reloads are coalesced, so a slow reload can never overwrite a newer play
  count.
- Domain: `LibraryUpdate.applyTo(list)` replaces/drops only affected songs,
  keeps every other `Song` instance identical, and returns `null` when nothing
  changed (no emission).
- A failed write sends nothing → the bloc can't show a value the database
  doesn't have.

### Results (median, 10,000 songs)

| Operation | Before | After | Full reads |
|---|---|---|---|
| Play | 31.1 ms | ~5 ms | 1 → 0 |
| Favourite | 30.2 ms | ~4 ms | 1 → 0 |
| Hide | 22.8 ms | ~5 ms | 1 → 0 |

### Where

- `lib/core/database/music_local_storage.dart` (`watchLibrary`)
- `lib/features/music_library/domain/entities/library_update.dart`
- `lib/features/music_library/presentation/logic/music_library_bloc.dart`
- Tests: `test/features/music_library/library_live_updates_test.dart`,
  benchmark `test/perf/library_updates_perf_test.dart`

### Learn more

- Isar (community edition) package and docs links:
  https://pub.dev/packages/isar_community
- Flutter performance best practices:
  https://docs.flutter.dev/perf/best-practices
- Immutability and identity-based change detection (why keeping unchanged
  instances matters): Equatable — https://pub.dev/packages/equatable
- Event ordering / "read your writes" consistency: *Designing Data-Intensive
  Applications*, chapter on replication and consistency guarantees.

---

## 5. Albums and artists read the database twice

### Problem

`LibraryCollectionsCubit.load()` called `getAlbums()` and `getArtists()`; each
read all songs from Isar — although the same songs were already in memory.

### Fix

- The grouping algorithm moved unchanged to the domain layer
  (`lib/features/music_library/domain/entities/catalog_grouping.dart`). It is
  **generic** (`GroupingFields<T>`), so the *same code* groups in-memory
  `Song`s and database rows.
- `BuildLibraryCatalogUseCase` builds albums/artists from the bloc's songs.
- Regrouping still only happens when grouping fields change (`catalogChanged`).

### Results

16.0 ms and 20,000 rows read → 5–9 ms and 0 rows.

### How "identical results" was proven

The test compares the new output with a **verbatim copy of the old code taken
from git** (`test/support/legacy_library_grouping.dart`), on edge cases:
missing album ids, artists differing only by case, mixed-artist albums.

### Learn more

- Generics in Dart: https://dart.dev/language/generics
- "Characterization tests" (testing new code against the old behaviour):
  Michael Feathers, *Working Effectively with Legacy Code*.

---

## 6. Tap-to-play lag: 10,000 AudioSources

### Problem

Tapping a song in the Songs tab **froze the UI ~392 ms** (10,000 songs),
growing linearly with list size. Albums felt fine; the full library didn't.

### Root cause (measured, not guessed)

`playSongs(sorted, index)` passed the entire visible library as the queue.
just_audio then, on the main isolate, in one unbroken block:

1. created 10,000 `AudioSource.uri` (each with a random UUID) — 22–39 ms;
2. initialised the playlist, shuffle order and sequence — 67–100 ms;
3. awaited `_onLoad()` once per song (when a song had played before), shuffled
   and rebuilt the sequence again, and built 10,000 platform messages
   (≈1.3 MB) — 171–194 ms;
4. waited for the native player to prepare the whole playlist.

Dart's single-threaded event loop can't draw frames during such a block.

### Fix — sliding window playlist

- `PlaybackQueue` (`lib/features/player/data/queue/playback_queue.dart`) keeps
  the **complete logical queue** and the play order.
- just_audio receives only a **window**: 2 songs behind, the current one, 4
  ahead (or the whole queue if it has ≤ 7 songs).
- The window slides in **batches**: fewer than 2 ahead → load up to 8 ahead;
  more than 6 behind → trim to 2. Max 15 loaded.
- **Two indexes**:
  - *logical index* — position in the full queue (shown in UI, saved to disk);
  - *player index* — position inside just_audio's window.
  Mapping goes through each item's tag (`_Slot`: logical index, play position,
  generation), never through window offsets.
- **Shuffle** is done over the *whole* queue in the repository (stable order,
  current song first, like just_audio's own shuffle). just_audio's shuffle is
  never enabled.
- **Repeat all** is done by continuing the window past the end (positions
  wrap); queues that fit the window use just_audio's `LoopMode.all`.
  **Repeat one** uses `LoopMode.one` (Next/Previous restart the song, as
  before).
- **Serial operations**: loads, Next/Previous, window updates, shuffle/repeat
  changes and restore never overlap (just_audio ignores `seek` while loading,
  and inserting/removing before the current item shifts its index).

### Results (median)

| | Before: 12 / 1,000 / 10,000 songs | After: 12 / 1,000 / 10,000 songs |
|---|---|---|
| Tapped song shown | 8.2 / 62.9 / **392 ms** | 0.1 / 0.2 / **0.5 ms** |
| Play reaches native | 8.1 / 62.9 / 392 ms | 5.3 / 6.9 / **6.9 ms** |
| AudioSources sent | 12 / 1,000 / 10,000 | 5 / 7 / **7** |
| Longest UI freeze | 8.6 / 63.2 / **392 ms** | 5.6 / 7.4 / **7.2 ms** |
| Reloads per 100 auto-advances | 0 | 0 |
| Playlist updates per 100 auto-advances | 0 | 33 (small) |

### Where

- `lib/features/player/data/repositories/player_repository_impl.dart`
- `lib/features/player/data/queue/playback_queue.dart`
- Tests: `test/features/player/player_window_test.dart` (27 tests on the
  **real** `AudioPlayer` with a simulated native side:
  `test/support/fake_audio_native.dart`), benchmark
  `test/perf/player_window_perf_test.dart`

### Learn more

- Dart concurrency and the event loop (why a long synchronous block drops
  frames): https://dart.dev/language/concurrency
- Flutter isolates (and why moving work to an isolate was *not* the answer
  here — the plugin lives on the main isolate, and the real fix is to not do
  the work): https://docs.flutter.dev/perf/isolates
- Flutter UI performance and DevTools Performance view:
  https://docs.flutter.dev/perf/ui-performance and
  https://docs.flutter.dev/tools/devtools/performance
- just_audio package and source (read `setAudioSources`, `_load`,
  `ConcatenatingAudioSource`): https://pub.dev/packages/just_audio and
  https://github.com/ryanheise/just_audio
- ExoPlayer / Media3 playlists (what the native side does):
  https://developer.android.com/media/media3/exoplayer/playlists
- The same idea in UI lists — load only what's visible:
  `ListView.builder` https://api.flutter.dev/flutter/widgets/ListView/ListView.builder.html
- Fisher–Yates shuffle (how `List.shuffle` works):
  https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle

---

## 7. Wrong-song flash after a tap

### Problem

After tapping song 108 while song 3 of another album played, the first 7
states reported **song 103**: the new queue combined with the *old* player
index.

### Fix

A "pending" display (generalised from the existing session-restore
mechanism): the tapped song and its logical index are published immediately
and shown until loading finishes. A newer tap replaces an older pending one.

---

## 8. Earlier fixes worth remembering

- **Isar bools are three-state** (`null` / `false` / `true`). Use
  `not().isHiddenEqualTo(true)` for visible songs; `isHiddenEqualTo(false)`
  hid all songs saved before the field existed.
- **Marquee in `LayoutBuilder`** relaid out the page every frame → switched to
  a `Flow` delegate.
- **Name clash**: domain `RepeatMode` vs Flutter → renamed `PlaybackRepeat`.
- **Rebuild control**: `buildWhen: changedBesidesProgress` (compare the queue
  by identity, ignore position ticks), `BlocSelector` per song row,
  `RepaintBoundary` around animated parts, kept-alive tabs, reused sorted
  lists.
- **Incremental MediaStore sync** with per-volume `GENERATION_MODIFIED`
  checkpoints; deletions found by comparing ids (generations never report
  deletions).

### Learn more

- `RepaintBoundary` and repaint isolation:
  https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html
- `Flow` widget: https://api.flutter.dev/flutter/widgets/Flow-class.html
- `AutomaticKeepAliveClientMixin`:
  https://api.flutter.dev/flutter/widgets/AutomaticKeepAliveClientMixin-mixin.html

---

## 9. Testing techniques used

| Technique | Why | Example |
|---|---|---|
| **Real database in tests** | Catches transaction, ordering and query bugs mocks hide | Real Isar via `test/support/isar_test_db.dart` |
| **Fake platform, real plugin code** | Tests just_audio's real Dart logic; only native is simulated | `fake_audio_native.dart` |
| **Mutation testing (manual)** | Re-introduce a bug and confirm a test fails. Found 3 weak tests | Removing serialisation was only caught after adding test 9b |
| **Fault injection** | Null cursors, `SecurityException`, failed commits, held operations | `FakeMediaStore` faults, `_CommitFailsIsar`, `holdLoad` / `holdUpdate` |
| **Characterization test** | Prove new code matches old behaviour exactly | Legacy grouping oracle |
| **Benchmark before changing code** | Measure, don't assume; run the same benchmark before and after | `test/perf/*_perf_test.dart` |
| **Main-isolate stall monitor** | A 1 ms timer; the longest gap = longest UI freeze | Player benchmark |

Practical notes:

- Run the suite with `flutter test -j 2` (the full run can be killed for
  memory otherwise).
- With endless animations use fixed `pump`s, not `pumpAndSettle`.
- Use `MediaQueryData.fromView(tester.view)` in widget tests.
- Verify with `flutter analyze` + tests; device behaviour is listed
  separately, not assumed.

### Learn more

- Flutter testing overview: https://docs.flutter.dev/testing/overview
- mocktail: https://pub.dev/packages/mocktail
- Mutation testing: https://en.wikipedia.org/wiki/Mutation_testing
- Benchmarking in Dart: https://pub.dev/packages/benchmark_harness
- Book: *Working Effectively with Legacy Code* (Michael Feathers).

---

## 10. Open items and device checks

**Device check (not verified yet):**

- [ ] `MainActivity.kt` compiles and the media-store channel works.
- [ ] Revoke music access in Settings while the app is open → library stays,
      permission prompt appears.
- [ ] Android 13+, Android 11–12, and Android ≤ 10 (native full scan).
- [ ] Eject an SD card during a sync → fails safely, next sync catches up.
- [ ] Player window: gapless move into newly added songs; adding/removing
      songs before the current one doesn't interrupt it or flash another song;
      rapid Next/Previous; long shuffle and repeat-all sessions.
- [ ] Profile-mode DevTools timeline for tap-to-play and song start.
- [ ] Android Studio profiler for the native side:
      https://developer.android.com/studio/profile

**Small leftovers (low priority):**

- `GetAlbumsUseCase` / `GetArtistsUseCase` are registered but unused.
- `saveQueue` stores queue ids twice (runs in the background).
- Shuffle order isn't persisted across restarts (same as before).
- Hidden Songs page still uses an Isar watcher (only while open).
- Hiding a song rebuilds search keys in memory.
- Player window: ~33 small playlist updates per 100 songs.

---

## 11. Study plan and resources

A suggested order, each step building on the previous one:

1. **Dart's event loop and async** — why one long synchronous block freezes
   the UI, and what `await` does and doesn't do.
   - https://dart.dev/language/concurrency
   - https://dart.dev/libraries/async/async-await
2. **Flutter performance** — frames, rebuilds vs repaints, profiling.
   - https://docs.flutter.dev/perf/best-practices
   - https://docs.flutter.dev/perf/ui-performance
   - https://docs.flutter.dev/tools/devtools/performance
3. **State management with Bloc** — emissions, equality, `buildWhen`,
   selectors.
   - https://bloclibrary.dev
4. **Clean Architecture and SOLID** — boundaries, interfaces, dependency
   direction.
   - https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
   - Books: *Clean Architecture*; *Agile Software Development: Principles,
     Patterns, and Practices* (Robert C. Martin)
5. **Design patterns** used here (Strategy, Mediator, Repository, Mapper,
   Template Method). Resource: https://refactoring.guru/design-patterns
6. **Android storage and permissions** — scoped storage, MediaStore,
   generations.
   - https://developer.android.com/training/data-storage/shared/media
   - https://developer.android.com/reference/android/provider/MediaStore
7. **Platform channels** — how Dart talks to Kotlin, error codes, message cost.
   - https://docs.flutter.dev/platform-integration/platform-channels
8. **Data safety and consistency** — fail-safe defaults, transactions,
   ordering.
   - Books: *Release It!* (Nygard); *Designing Data-Intensive Applications*
     (Kleppmann)
9. **Audio playback** — just_audio internals and ExoPlayer playlists.
   - https://github.com/ryanheise/just_audio
   - https://developer.android.com/media/media3/exoplayer/playlists
10. **Testing** — fakes vs mocks, fault injection, characterization and
    mutation testing.
    - https://docs.flutter.dev/testing/overview
    - Book: *Working Effectively with Legacy Code* (Feathers)

**Hands-on exercises** (to really learn it):

- Re-run `test/perf/player_window_perf_test.dart` with a bigger window
  (`windowAhead: 10`) and see how updates per 100 songs change.
- Break one rule on purpose (e.g. send a storage update *before* the commit)
  and watch which test in `library_live_updates_test.dart` fails.
- Open DevTools in profile mode on a device and record tapping a song, then
  compare with the numbers above.
