import 'package:melodix/core/config/theme/app_accent.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements Storage {}

void main() {
  setUp(() {
    final storage = MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  test('starts with the original designs', () {
    expect(UiPreferencesCubit().state, UiPreferences.defaults);
    expect(UiPreferences.defaults.miniPlayer, MiniPlayerStyle.classic);
    expect(UiPreferences.defaults.selectionBar, SelectionBarStyle.bottom);
  });

  test('each choice is kept apart', () {
    final cubit = UiPreferencesCubit()..setMiniPlayer(MiniPlayerStyle.capsule);
    expect(cubit.state.miniPlayer, MiniPlayerStyle.capsule);
    expect(cubit.state.selectionBar, SelectionBarStyle.bottom);
    cubit.setSelectionBar(SelectionBarStyle.side);
    expect(cubit.state.miniPlayer, MiniPlayerStyle.capsule);
    expect(cubit.state.selectionBar, SelectionBarStyle.side);
  });

  test('saved and restored by name, every combination', () {
    final cubit = UiPreferencesCubit();
    for (final mini in MiniPlayerStyle.values) {
      for (final bar in SelectionBarStyle.values) {
        for (final accent in AppAccent.values) {
          final prefs = UiPreferences(
            miniPlayer: mini,
            selectionBar: bar,
            accent: accent,
          );
          expect(cubit.fromJson(cubit.toJson(prefs)!), prefs);
        }
      }
    }
  });

  test('the accent: green at first; settable on its own', () {
    final cubit = UiPreferencesCubit();
    expect(cubit.state.accent, AppAccent.green);
    cubit.setAccent(AppAccent.red);
    expect(cubit.state.accent, AppAccent.red);
    expect(cubit.state.miniPlayer, MiniPlayerStyle.classic);
  });

  test("a name it doesn't know (another app version) falls back", () {
    final restored = UiPreferencesCubit().fromJson({
      'miniPlayer': 'hologram',
      'selectionBar': 42,
      'accent': 'ultraviolet',
    });
    expect(restored, UiPreferences.defaults);
  });

  testWidgets('without a scope above, screens get the original designs', (
    tester,
  ) async {
    late UiPreferences seen;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seen = UiPreferencesScope.of(context);
          return const SizedBox();
        },
      ),
    );
    expect(seen, UiPreferences.defaults);
  });
}
