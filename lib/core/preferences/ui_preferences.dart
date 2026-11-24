import 'package:melodix/core/config/theme/app_accent.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// How the music mini player looks.
enum MiniPlayerStyle {
  /// The card with title, controls and a seek bar (the original).
  classic,

  /// A floating pill: round cover with a progress ring, play and next.
  capsule,

  /// A flat bar with a thin progress line along its top.
  minimal,
}

/// Where the actions for selected songs / videos appear.
enum SelectionBarStyle {
  /// A bar along the bottom (the original).
  bottom,

  /// A vertical bar down the right edge.
  side,
}

/// Look and layout choices the user makes in Settings.
class UiPreferences extends Equatable {
  const UiPreferences({
    this.miniPlayer = MiniPlayerStyle.classic,
    this.selectionBar = SelectionBarStyle.bottom,
    this.accent = AppAccent.green,
  });

  /// The original designs.
  static const defaults = UiPreferences();

  final MiniPlayerStyle miniPlayer;
  final SelectionBarStyle selectionBar;

  /// The accent colour (the app's green unless the user picked another).
  final AppAccent accent;

  UiPreferences copyWith({
    MiniPlayerStyle? miniPlayer,
    SelectionBarStyle? selectionBar,
    AppAccent? accent,
  }) => UiPreferences(
    miniPlayer: miniPlayer ?? this.miniPlayer,
    selectionBar: selectionBar ?? this.selectionBar,
    accent: accent ?? this.accent,
  );

  @override
  List<Object?> get props => [miniPlayer, selectionBar, accent];
}

/// The user's layout choices, saved across restarts (like the theme).
class UiPreferencesCubit extends HydratedCubit<UiPreferences> {
  UiPreferencesCubit() : super(UiPreferences.defaults);

  void setMiniPlayer(MiniPlayerStyle style) =>
      emit(state.copyWith(miniPlayer: style));

  void setSelectionBar(SelectionBarStyle style) =>
      emit(state.copyWith(selectionBar: style));

  void setAccent(AppAccent accent) => emit(state.copyWith(accent: accent));

  @override
  UiPreferences? fromJson(Map<String, dynamic> json) => UiPreferences(
    miniPlayer: _byName(
      MiniPlayerStyle.values,
      json['miniPlayer'],
      MiniPlayerStyle.classic,
    ),
    selectionBar: _byName(
      SelectionBarStyle.values,
      json['selectionBar'],
      SelectionBarStyle.bottom,
    ),
    accent: _byName(AppAccent.values, json['accent'], AppAccent.green),
  );

  @override
  Map<String, dynamic>? toJson(UiPreferences state) => {
    'miniPlayer': state.miniPlayer.name,
    'selectionBar': state.selectionBar.name,
    'accent': state.accent.name,
  };

  /// Saved by name (not index): adding a style later can't shift choices;
  /// an unknown name (an older or newer app) falls back to the original.
  static T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}

/// The current [UiPreferences] for everything below it.
class UiPreferencesScope extends InheritedWidget {
  const UiPreferencesScope({
    super.key,
    required this.preferences,
    required super.child,
  });

  final UiPreferences preferences;

  /// The preferences above [context]; the original designs if there are
  /// none (e.g. a screen shown on its own).
  static UiPreferences of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<UiPreferencesScope>()
          ?.preferences ??
      UiPreferences.defaults;

  @override
  bool updateShouldNotify(UiPreferencesScope old) =>
      old.preferences != preferences;
}
