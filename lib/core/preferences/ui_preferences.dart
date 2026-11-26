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

/// How big video captions are.
enum SubtitleSize {
  small(0.85),
  medium(1),
  large(1.25),
  huge(1.55);

  const SubtitleSize(this.scale);

  /// Times the original caption size.
  final double scale;
}

/// What sits behind video captions.
enum SubtitleLook {
  /// A soft dark box (the original).
  box,

  /// No box: an outline and shadow around the letters.
  outline,
}

/// The colour of video captions.
enum SubtitleColor {
  white,
  yellow,

  /// The app's accent.
  accent,
}

/// What fills the Now Playing screen behind the controls.
enum NowPlayingBackground {
  /// The app's background (the original).
  plain,

  /// The song's cover, blurred and dimmed.
  cover,

  /// The accent's glow, drifting (as on the onboarding).
  glow,
}

/// Look and layout choices the user makes in Settings.
class UiPreferences extends Equatable {
  const UiPreferences({
    this.miniPlayer = MiniPlayerStyle.classic,
    this.selectionBar = SelectionBarStyle.bottom,
    this.accent = AppAccent.green,
    this.dynamicAccent = false,
    this.videoSeekSeconds = 10,
    this.subtitleSize = SubtitleSize.medium,
    this.subtitleLook = SubtitleLook.box,
    this.subtitleColor = SubtitleColor.white,
    this.nowPlayingBackground = NowPlayingBackground.plain,
  });

  /// The jumps the user can pick for the video player's skip buttons and
  /// double-taps.
  static const List<int> videoSeekChoices = [5, 10, 15, 30];

  /// The original designs.
  static const defaults = UiPreferences();

  final MiniPlayerStyle miniPlayer;
  final SelectionBarStyle selectionBar;

  /// The accent colour (the app's green unless the user picked another).
  final AppAccent accent;

  /// While a song plays, the accent comes from its cover ([accent] when
  /// the cover has no clear colour, or nothing plays).
  final bool dynamicAccent;

  /// How far the video player's skip buttons and double-taps jump (one of
  /// [videoSeekChoices]).
  final int videoSeekSeconds;

  final SubtitleSize subtitleSize;
  final SubtitleLook subtitleLook;
  final SubtitleColor subtitleColor;

  final NowPlayingBackground nowPlayingBackground;

  Duration get videoSeekStep => Duration(seconds: videoSeekSeconds);

  UiPreferences copyWith({
    MiniPlayerStyle? miniPlayer,
    SelectionBarStyle? selectionBar,
    AppAccent? accent,
    bool? dynamicAccent,
    int? videoSeekSeconds,
    SubtitleSize? subtitleSize,
    SubtitleLook? subtitleLook,
    SubtitleColor? subtitleColor,
    NowPlayingBackground? nowPlayingBackground,
  }) => UiPreferences(
    miniPlayer: miniPlayer ?? this.miniPlayer,
    selectionBar: selectionBar ?? this.selectionBar,
    accent: accent ?? this.accent,
    dynamicAccent: dynamicAccent ?? this.dynamicAccent,
    videoSeekSeconds: videoSeekSeconds ?? this.videoSeekSeconds,
    subtitleSize: subtitleSize ?? this.subtitleSize,
    subtitleLook: subtitleLook ?? this.subtitleLook,
    subtitleColor: subtitleColor ?? this.subtitleColor,
    nowPlayingBackground: nowPlayingBackground ?? this.nowPlayingBackground,
  );

  @override
  List<Object?> get props => [
    miniPlayer,
    selectionBar,
    accent,
    dynamicAccent,
    videoSeekSeconds,
    subtitleSize,
    subtitleLook,
    subtitleColor,
    nowPlayingBackground,
  ];
}

/// The user's layout choices, saved across restarts (like the theme).
class UiPreferencesCubit extends HydratedCubit<UiPreferences> {
  UiPreferencesCubit() : super(UiPreferences.defaults);

  void setMiniPlayer(MiniPlayerStyle style) =>
      emit(state.copyWith(miniPlayer: style));

  void setSelectionBar(SelectionBarStyle style) =>
      emit(state.copyWith(selectionBar: style));

  /// A fixed colour (cover colours off).
  void setAccent(AppAccent accent) =>
      emit(state.copyWith(accent: accent, dynamicAccent: false));

  void setDynamicAccent(bool enabled) =>
      emit(state.copyWith(dynamicAccent: enabled));

  void setVideoSeekSeconds(int seconds) {
    if (UiPreferences.videoSeekChoices.contains(seconds)) {
      emit(state.copyWith(videoSeekSeconds: seconds));
    }
  }

  void setSubtitleSize(SubtitleSize size) =>
      emit(state.copyWith(subtitleSize: size));

  void setSubtitleLook(SubtitleLook look) =>
      emit(state.copyWith(subtitleLook: look));

  void setSubtitleColor(SubtitleColor color) =>
      emit(state.copyWith(subtitleColor: color));

  void setNowPlayingBackground(NowPlayingBackground background) =>
      emit(state.copyWith(nowPlayingBackground: background));

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
    dynamicAccent: json['dynamicAccent'] == true,
    videoSeekSeconds:
        UiPreferences.videoSeekChoices.contains(json['videoSeekSeconds'])
        ? json['videoSeekSeconds'] as int
        : UiPreferences.defaults.videoSeekSeconds,
    subtitleSize: _byName(
      SubtitleSize.values,
      json['subtitleSize'],
      SubtitleSize.medium,
    ),
    subtitleLook: _byName(
      SubtitleLook.values,
      json['subtitleLook'],
      SubtitleLook.box,
    ),
    subtitleColor: _byName(
      SubtitleColor.values,
      json['subtitleColor'],
      SubtitleColor.white,
    ),
    nowPlayingBackground: _byName(
      NowPlayingBackground.values,
      json['nowPlayingBackground'],
      NowPlayingBackground.plain,
    ),
  );

  @override
  Map<String, dynamic>? toJson(UiPreferences state) => {
    'miniPlayer': state.miniPlayer.name,
    'selectionBar': state.selectionBar.name,
    'accent': state.accent.name,
    'dynamicAccent': state.dynamicAccent,
    'videoSeekSeconds': state.videoSeekSeconds,
    'subtitleSize': state.subtitleSize.name,
    'subtitleLook': state.subtitleLook.name,
    'subtitleColor': state.subtitleColor.name,
    'nowPlayingBackground': state.nowPlayingBackground.name,
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

  /// The preferences above [context] without rebuilding when they change
  /// (for choices read once, like the tab to open on).
  static UiPreferences read(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<UiPreferencesScope>()
          ?.preferences ??
      UiPreferences.defaults;

  @override
  bool updateShouldNotify(UiPreferencesScope old) =>
      old.preferences != preferences;
}
