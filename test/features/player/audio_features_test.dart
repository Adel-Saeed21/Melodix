import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_accent.dart';
import 'package:melodix/core/config/theme/cover_palette.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/features/player/data/audio_settings_binder.dart';
import 'package:melodix/features/player/domain/entities/equalizer_preset.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/entities/playback_progress.dart';
import 'package:melodix/features/player/domain/repositories/equalizer_engine.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';
import 'package:melodix/features/player/presentation/logic/audio_settings_cubit.dart';
import 'package:melodix/features/player/presentation/logic/cover_accent_cubit.dart';
import 'package:melodix/features/player/presentation/logic/sleep_timer_cubit.dart';
import 'package:mocktail/mocktail.dart';

import 'player_fixtures.dart';

class _Player extends Mock implements PlayerRepository {}

class _Equalizer implements EqualizerEngine {
  bool? enabled;
  double Function(double hz)? gains;

  @override
  bool get isSupported => true;

  @override
  Future<void> setEnabled(bool enabled) async => this.enabled = enabled;

  @override
  Future<void> setGains(double Function(double hz) gainAtHz) async =>
      gains = gainAtHz;
}

Uint8List _image(List<Color> pixels) => Uint8List.fromList([
  for (final c in pixels) ...[
    (c.r * 255).round(),
    (c.g * 255).round(),
    (c.b * 255).round(),
    255,
  ],
]);

NowPlaying _playing(int id, {bool playing = true}) => NowPlaying(
  queue: [playerSong(id)],
  currentIndex: 0,
  isPlaying: playing,
  duration: const Duration(minutes: 3),
);

void main() {
  setUpAll(registerPlayerFallbacks);
  setUp(() => HydratedBloc.storage = MemoryStorage());

  group('cover colours', () {
    test('a red cover gives a red accent', () {
      final color = CoverPalette.fromRgba(
        _image(List.filled(100, const Color(0xffD32F2F))),
      )!;
      final hue = HSLColor.fromColor(color).hue;
      expect(hue < 20 || hue > 340, isTrue, reason: '$hue');
    });

    test('the main colour wins over a few others', () {
      final color = CoverPalette.fromRgba(
        _image([
          ...List.filled(80, const Color(0xff1E88E5)), // blue
          ...List.filled(20, const Color(0xffFDD835)), // yellow
        ]),
      )!;
      final hue = HSLColor.fromColor(color).hue;
      expect(hue, inInclusiveRange(190, 230));
    });

    test('a grey or black-and-white cover gives none', () {
      expect(
        CoverPalette.fromRgba(
          _image([
            ...List.filled(50, const Color(0xff808080)),
            ...List.filled(50, Colors.black),
          ]),
        ),
        isNull,
      );
    });

    test('text on any colour stays readable', () {
      expect(AccentColors.onColorFor(const Color(0xff1E3A8A)), Colors.white);
      expect(
        AccentColors.onColorFor(const Color(0xffF5E663)),
        isNot(Colors.white),
      );
      for (final accent in AppAccent.values) {
        expect(AccentColors.onColorFor(accent.color), accent.onColor);
      }
    });

    test("follows the playing song's cover only while switched on", () async {
      final songs = StreamController<NowPlaying>.broadcast();
      final prefs = StreamController<UiPreferences>.broadcast();
      final cubit = CoverAccentCubit(
        nowPlaying: songs.stream,
        current: _playing(1),
        preferences: prefs.stream,
        enabled: false,
        artwork: (id) => Uint8List.fromList([id]),
        pick: (bytes) async => bytes.first == 1 ? Colors.red : Colors.blue,
      );
      await pumpEventQueue();
      expect(cubit.state, isNull); // off

      prefs.add(const UiPreferences(dynamicAccent: true));
      await pumpEventQueue();
      expect(cubit.state, Colors.red);

      songs.add(_playing(2));
      await pumpEventQueue();
      expect(cubit.state, Colors.blue);

      prefs.add(const UiPreferences());
      await pumpEventQueue();
      expect(cubit.state, isNull);
      await cubit.close();
      await songs.close();
      await prefs.close();
    });
  });

  group('equalizer', () {
    test('the curve passes through each band and is flat beyond', () {
      const gains = [6.0, 3.0, 0.0, -3.0, 2.0];
      for (var i = 0; i < gains.length; i++) {
        expect(gainAt(equalizerBandsHz[i], gains), closeTo(gains[i], 1e-9));
      }
      expect(gainAt(20, gains), 6);
      expect(gainAt(20000, gains), 2);
      final between = gainAt(120, gains);
      expect(between, inExclusiveRange(3, 6));
    });

    test('moving a bar makes the sound Custom, from the bars showing', () {
      final cubit = AudioSettingsCubit()..setPreset(EqualizerPreset.rock);
      expect(cubit.state.equalizerOn, isTrue);
      cubit.setBand(2, 4);
      expect(cubit.state.preset, EqualizerPreset.custom);
      expect(cubit.state.gains, [5, 2, 4, 2, 5]);
      cubit.setBand(0, 99); // clamped
      expect(cubit.state.gains.first, equalizerMaxGainDb);
    });

    test('saved and restored', () {
      final cubit = AudioSettingsCubit()
        ..setSpeed(1.5)
        ..setSkipSilence(true)
        ..setBand(1, -3);
      final restored = cubit.fromJson(cubit.toJson(cubit.state)!);
      expect(restored, cubit.state);
      expect(
        cubit.fromJson({'speed': 9, 'customGains': 'x'}),
        AudioSettings.defaults,
      );
    });

    test(
      'the binder applies the settings to the player and equalizer',
      () async {
        final player = _Player();
        when(() => player.setSpeed(any())).thenAnswer((_) async {});
        when(() => player.setSkipSilence(any())).thenAnswer((_) async {});
        final equalizer = _Equalizer();
        final cubit = AudioSettingsCubit();
        final binder = AudioSettingsBinder(
          settings: cubit.stream,
          initial: cubit.state,
          player: player,
          equalizer: equalizer,
        );
        verify(() => player.setSpeed(1)).called(1);
        expect(equalizer.enabled, isFalse);

        cubit
          ..setSpeed(1.25)
          ..setPreset(EqualizerPreset.bassBoost);
        await pumpEventQueue();
        verify(() => player.setSpeed(1.25)).called(1);
        expect(equalizer.enabled, isTrue);
        expect(equalizer.gains!(60), 6);
        await binder.dispose();
        await cubit.close();
      },
    );
  });

  group('sleep timer', () {
    late _Player player;
    late StreamController<NowPlaying> states;
    late StreamController<PlaybackProgress> progress;

    setUp(() {
      player = _Player();
      states = StreamController<NowPlaying>.broadcast();
      progress = StreamController<PlaybackProgress>.broadcast();
      when(() => player.current).thenReturn(_playing(1));
      when(() => player.progress).thenReturn(PlaybackProgress.zero);
      when(() => player.watch()).thenAnswer((_) => states.stream);
      when(() => player.watchProgress()).thenAnswer((_) => progress.stream);
      when(() => player.pause()).thenAnswer((_) async {});
      when(() => player.seek(any())).thenAnswer((_) async {});
      when(() => player.setVolume(any())).thenAnswer((_) async {});
    });

    // testWidgets: its clock is fake, so the countdown runs in no time.
    testWidgets('counts down, fades the last seconds, then pauses', (
      tester,
    ) async {
      final timer = SleepTimerCubit(player)..start(const Duration(minutes: 1));
      await tester.pump(const Duration(seconds: 30));
      expect(timer.state.remaining, const Duration(seconds: 30));
      verifyNever(() => player.setVolume(any()));

      await tester.pump(const Duration(seconds: 25)); // 5 s left: fading
      verify(() => player.setVolume(0.5)).called(1);

      await tester.pump(const Duration(seconds: 5));
      expect(timer.state, SleepTimerState.off);
      verify(() => player.pause()).called(1);
      // Loud again only after the pause (for next time).
      verify(() => player.setVolume(1)).called(1);
      await timer.close();
    });

    testWidgets('+5 min and off', (tester) async {
      final timer = SleepTimerCubit(player)
        ..start(const Duration(minutes: 1))
        ..extend(const Duration(minutes: 5));
      expect(timer.state.remaining, const Duration(minutes: 6));
      timer.cancel();
      await tester.pump(const Duration(minutes: 10));
      verifyNever(() => player.pause());
      await timer.close();
    });

    test(
      'end of song: pauses as the next one starts, back at its start',
      () async {
        final timer = SleepTimerCubit(player)..stopAtEndOfSong();
        expect(timer.state.endOfSong, isTrue);
        states.add(_playing(1)); // same song: nothing
        await pumpEventQueue();
        verifyNever(() => player.pause());

        states.add(_playing(2));
        await pumpEventQueue();
        verify(() => player.pause()).called(1);
        verify(() => player.seek(Duration.zero)).called(1);
        expect(timer.state, SleepTimerState.off);
        await timer.close();
      },
    );

    test('end of song with repeat-one: the song starting over', () async {
      final timer = SleepTimerCubit(player)..stopAtEndOfSong();
      progress
        ..add(
          const PlaybackProgress(
            position: Duration(minutes: 2, seconds: 59),
            duration: Duration(minutes: 3),
          ),
        )
        ..add(
          const PlaybackProgress(
            position: Duration(milliseconds: 300),
            duration: Duration(minutes: 3),
          ),
        );
      await pumpEventQueue();
      verify(() => player.pause()).called(1);
      await timer.close();
    });
  });
}
