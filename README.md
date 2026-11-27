# Melodix

Melodix is a Flutter music and video player for the media stored on your phone: it syncs your library, plays music in the background with lock-screen controls, plays videos with subtitles, finds lyrics, and keeps listening stats, in English or Arabic. It is built as a reference for a production-grade Flutter codebase: Clean Architecture with a feature-first layout, BLoC for state, GetIt for dependency injection, the Repository Pattern, build flavors, and a large automated test suite.

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [State Management](#state-management)
- [Dependency Injection](#dependency-injection)
- [Local Storage](#local-storage)
- [Navigation](#navigation)
- [Error Handling](#error-handling)
- [Localization (English / Arabic)](#localization-english--arabic)
- [Theming and Responsive Layout](#theming-and-responsive-layout)
- [Build Flavors](#build-flavors)
- [Getting Started](#getting-started)
- [Testing](#testing)
- [Code Generation](#code-generation)
- [Contributing](#contributing)

## Features

| Area | What it does |
| --- | --- |
| Onboarding | Animated intro (drawn in code) ending with the dark / light / auto choice |
| Music library | Reads the phone's music through MediaStore; incremental sync (only what changed); songs, albums, artists and playlists; sorting, multi-select, delete from phone; music filters (shortest song, hidden folders) |
| Search | Searches songs, artists, albums, playlists and videos; remembers the last searches and what was opened from search |
| Player | Background playback with notification and lock-screen controls; queue, shuffle, repeat; speed, skip silence, equalizer; sleep timer; colours taken from the cover |
| Lyrics | Synced or plain lyrics from the song file, an `.lrc` file, or LRCLIB; the sung line follows the song |
| Video | The phone's videos with "Continue watching"; a full player, a small floating window and picture-in-picture |
| Subtitles | `.srt` / `.vtt` files next to the video or imported, or downloaded from OpenSubtitles, kept for offline use |
| Listening stats | Plays and time really listened to (skips don't count), top songs and artists |
| Settings | Theme, accent colour, app icon, music bar and selection bar styles, video skip length, subtitle style, language |
| Languages | English and Arabic, right to left, with a smooth fade when switching |

## Tech Stack

| Concern | Technology |
| --- | --- |
| Framework | Flutter (Dart SDK ^3.13) |
| State management | `flutter_bloc`, `hydrated_bloc` (saved preferences) |
| Dependency injection | `get_it` |
| Navigation | `go_router` |
| Local database | `isar_community` |
| Music | `on_audio_query` (MediaStore), `just_audio`, `audio_service`, `audio_session` |
| Video | `photo_manager` (MediaStore), `video_player` |
| Networking | `dio`, `retrofit` (OpenSubtitles) |
| Localization | `easy_localization`, with a typed `AppLocalizations` on top |
| Functional error handling | `dartz` (`Either<Failure, T>`) |
| Value equality | `equatable` |
| Code generation | `build_runner`, `freezed`, `json_serializable`, `retrofit_generator`, `isar_community_generator` |
| Responsive UI | `flutter_screenutil_plus` |
| Testing | `flutter_test`, `mocktail` |
| Static analysis | `flutter_lints` |

The app runs on Android. Reading music relies on Android's MediaStore.

## Architecture

The codebase follows **Clean Architecture**, organized **by feature**. Each feature has three layers with a strict dependency rule: outer layers depend on inner ones, never the reverse.

```
Presentation  ->  Domain  <-  Data
(pages, widgets,  (entities,    (repository implementations,
 Bloc / Cubit)     use cases,    mappers, data sources)
                   repository
                   contracts)
```

- **Domain** is plain Dart: entities (`Song`, `Video`), repository contracts (`SongRepository`, `VideoSyncRepository`) and use cases that each do one thing and return `Future<Either<Failure, T>>`.
- **Data** implements the contracts on top of shared services and storage in `core/` (MediaStore readers, the Isar database), and turns exceptions into `Failure`s.
- **Presentation** holds pages, widgets and the Bloc / Cubit for each screen. Widgets never call services directly.

Features stay independent: where one feature needs another, the dependency points one way (for example, lyrics define a small `LyricsClock` interface that the player implements, so lyrics don't depend on the player).

A library sync flows through the layers like this:

```
MusicLibraryBloc          (app start, return to the app, Scan button)
  -> SyncMusicLibraryUseCase
  -> LibrarySyncRepository          (domain contract)
  -> LibrarySyncRepositoryImpl      (checks permission, reads MediaStore's
                                     checkpoint, plans: skip / incremental / full)
  -> IncrementalLibraryScan or FullLibraryScan
  -> MusicLocalStorage (Isar)       (one transaction; never wipes on a failed read)
  <- Either<Failure, LibrarySyncResult>
```

The design decisions and the problems they solve (data safety, performance, playback) are written up in [`docs/engineering-notes.md`](docs/engineering-notes.md).

## Project Structure

```
lib/
├── main_dev.dart / main_production.dart   # Entry points per flavor
├── melodix_app.dart                       # Root: app-wide providers, theme, router, locale
├── core/
│   ├── config/
│   │   ├── dependency_injection/  # get_it.dart + core_injection.dart
│   │   ├── routing/               # GoRouter routes and transitions
│   │   └── theme/                 # Colours, accents, text sizes, themes
│   ├── database/                  # Isar collections and local storages
│   ├── errors/                    # Failures, exceptions, error messages
│   ├── l10n/                      # Typed texts, easy_localization set-up, language switch
│   ├── preferences/               # Saved settings (UI, filters, language)
│   ├── search/                    # Search sources and search history
│   ├── service/                   # MediaStore, permissions, lifecycle, media session
│   ├── usecase/                   # Base UseCase contract
│   └── widgets/                   # Shared widgets
└── features/
    ├── splash/ · onboarding/ · navigation/ · home_screen/
    ├── music_library/ · player/ · lyrics/
    ├── video/ · subtitles/
    ├── stats/ · settings/
    └── <feature>/
        ├── data/            # repositories, mappers, data sources
        ├── domain/          # entities, repositories, use cases
        ├── presentation/    # pages, widgets, logic (Bloc / Cubit)
        └── <feature>_injection.dart

assets/translations/         # en.json, ar.json
test/                        # Mirrors lib/, plus test/perf and test/support
docs/engineering-notes.md
```

## State Management

State uses the **BLoC pattern** with `flutter_bloc`.

- **Bloc** for event-driven, long-running work: `MusicLibraryBloc` handles start-up, refreshes, returning to the app and permission changes.
- **Cubit** for everything simpler: the player (`PlayerCubit`), the video session (`VideoPlayerCubit`), search, playlists, stats.
- **HydratedCubit** for preferences that must survive a restart (theme, UI choices, music filters, language, search history) without manual storage code.
- **Equatable** on states and parameters, so identical states don't rebuild anything.

Where state lives depends on who uses it. App-wide state (the player, the video session, preferences) is provided once at the root with `MultiBlocProvider`, because several screens and the overlays above them share it. Screen state is created with the screen and closed when you leave it.

## Dependency Injection

Dependencies are registered with `get_it`. Each feature owns its wiring in a `<feature>_injection.dart` module (`registerVideo(getIt)`, `registerPlayer(getIt)`…), and `core_injection.dart` registers what every feature shares (the database, platform services, preferences). `setupGetIt()` only calls the modules.

| Registration | Lifetime | Examples |
| --- | --- | --- |
| Services, repositories, use cases | Lazy singleton | `SongRepository`, `SyncVideoLibraryUseCase` |
| App-wide cubits | Lazy singleton | `PlayerCubit`, `VideoPlayerCubit` |
| Screen cubits | Factory (a fresh one per visit) | `VideoLibraryCubit`, `LyricsCubit` |

Everything is registered against its abstract type, so tests can swap in fakes.

## Local Storage

The library, playlists, favourites, play history, listening time and video progress are stored in **Isar**. A few rules keep the user's data safe:

- A sync writes in one transaction, and never empties the library because a read failed.
- Favourites, play counts and playlists survive re-scans.
- A song that disappears (for example, an SD card taken out) keeps its listening history, and gets it back if it returns.

## Navigation

Routing uses `go_router` with path-based routes (`Routes`) and a shared slide-and-fade page transition that follows the reading direction (from the right in English, from the left in Arabic). The Music, Video and Settings tabs live in an `IndexedStack` and are built on first visit, so the Video tab doesn't scan the phone at launch.

## Error Handling

Errors don't cross layers as exceptions. Repositories catch platform errors and return `Left(Failure)`; Blocs and Cubits fold the `Either` into a state or a message. Failure messages are identifiers (`ErrorMessages`) that the UI shows translated.

## Localization (English / Arabic)

Texts live in `assets/translations/en.json` and `ar.json` and are read with `easy_localization`, through a typed `AppLocalizations` class: screens write `context.l10n.songs` or `context.l10n.songsCount(3)`, so a typo doesn't compile.

- Arabic uses its real plural forms (one, two, a few, many).
- Layouts use start / end (`EdgeInsetsDirectional`, `AlignmentDirectional`) so the whole app mirrors in Arabic. The video player is the exception, on purpose: double-tapping the right side always skips forward.
- The language is "same as the phone", English or Arabic (Settings), and switching fades the screen out and back in, keeping the page and what's playing.
- Material's own texts (tooltips, dialogs, text menus) are translated too.

**Adding a text:** add it to both JSON files, then add its member and key to `lib/core/l10n/app_localizations.dart`. A test checks that the files and the code match.

## Theming and Responsive Layout

- Light and dark themes in `AppTheme`, with a choice of accent colours, or colours taken from the playing song's cover.
- The **Satoshi** font family, bundled in five weights.
- Layouts scale with `flutter_screenutil_plus` against a 375 × 812 design size, and adapt to landscape (the tab bar becomes a side rail).
- A native splash screen with light and dark variants (`flutter_native_splash.yaml`).

## Build Flavors

| Flavor | Entry point | Use |
| --- | --- | --- |
| `dev` | `lib/main_dev.dart` | Development |
| `production` | `lib/main_production.dart` | Releases |

Flavors are configured for Android in `android/app/build.gradle.kts`. Both currently use the application ID `com.example.spotify`, so only one can be installed at a time.

### OpenSubtitles API key

Online subtitle search reads its key from `config/opensubtitles.json`, which is git-ignored. Create it once:

```bash
cp config/opensubtitles.example.json config/opensubtitles.json   # then put your key in it
```

Without the file (or with an empty key) the app still runs: local subtitles work and online search is hidden. The key is compiled into the app, so `.gitignore` only keeps it out of git; it doesn't hide it from someone unpacking the APK.

Run a flavor:

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/opensubtitles.json
flutter run --flavor production -t lib/main_production.dart --dart-define-from-file=config/opensubtitles.json
```

Build a release (obfuscated, with the key, keeping debug symbols in `release-symbols/<version>/`):

```bash
tool/build_release.sh
```

Back up the symbols of every released version: obfuscated crash reports can only be read with them (`flutter symbolize`).

VS Code launch configurations for both flavors are in `.vscode/launch.json`.

## Getting Started

### Prerequisites

- Flutter SDK with Dart 3.13 or later
- Android Studio, with an Android emulator or device that has some music and videos on it

### Install and run

```bash
git clone https://github.com/Adel-Saeed21/Spotify.git
cd Spotify
flutter pub get
cp config/opensubtitles.example.json config/opensubtitles.json   # optional: add a key
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/opensubtitles.json
```

On first launch, allow access to music and videos when the app asks.

## Testing

Tests live under `test/` and mirror `lib/` (96 test files, about 870 tests).

- **Unit tests** for use cases, repositories, storage (against a real Isar database in a temp folder) and every Bloc / Cubit.
- **Widget tests** for screens, including Arabic right-to-left layouts.
- **Integration-style tests** that run the real `just_audio` player and repository against a simulated native player (`test/support/fake_audio_native.dart`) and a simulated MediaStore.
- **Performance tests** (`test/perf/`) that guard rebuilds, repaints, database reads and timings for large libraries (10,000 songs).
- Mocks use `mocktail`. `test/flutter_test_config.dart` loads the English texts for every test.

```bash
flutter test               # everything
flutter test test/perf     # performance tests only
flutter test --coverage
flutter analyze
```

## Code Generation

Isar collections, `freezed` / `json_serializable` models and the Retrofit client are generated. After changing one, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run the full build. Limiting it with `--build-filter` can delete the other generated files.

To regenerate the native splash screen after editing `flutter_native_splash.yaml`:

```bash
dart run flutter_native_splash:create
```

## Contributing

1. Branch from `main` (`feature/<name>`, `refactor/<name>`).
2. Keep each feature under `lib/features/<feature>/` with `data`, `domain` and `presentation`, and register it in its own `<feature>_injection.dart`.
3. Put user-facing text in both translation files, and use start / end (not left / right) in layouts.
4. Add or update tests for new logic.
5. Make sure `flutter analyze` and `flutter test` pass before opening a pull request.

## Disclaimer

This is an educational project, built to practise architecture and engineering patterns in Flutter. It is not affiliated with Spotify or any commercial music service.
