import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;
import 'package:melodix/core/errors/error_messages.dart';
import 'package:melodix/core/l10n/app_localizations.dart';

export 'package:melodix/core/l10n/app_localizations.dart';

/// Everything the app's [WidgetsApp] needs to speak English and Arabic:
/// easy_localization's (the app's texts, and the text direction), plus
/// Material's and Cupertino's own texts (tooltips, dialogs, text field
/// menus) for the `material_ui` / `cupertino_ui` widgets this app uses
/// (easy_localization's list only has the pre-3.47 ones, which those
/// widgets don't read: they'd stay in English).
List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates(
  BuildContext context,
) => [
  ...context.localizationDelegates,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// The app's texts in the user's language: `context.l10n.songs`.
///
/// Reading them through [BuildContext] makes a widget rebuild when the
/// language changes.
extension L10nContext on BuildContext {
  /// The texts in the language in use (English where no app is around, e.g.
  /// a widget shown on its own in a test).
  AppLocalizations get l10n {
    EasyLocalization.of(this); // rebuild this widget on a language change
    return const AppLocalizations();
  }
}

/// Texts put together from translated parts, and numbers formatted the
/// same in every language.
extension AppLocalizationsFormats on AppLocalizations {
  /// 1×, 1.5×, 0.75×.
  String speedValue(double speed) =>
      '${speed.toStringAsFixed(speed == speed.roundToDouble() ? 0 : 2).replaceFirst(RegExp(r'0$'), '')}×';

  /// An equalizer band: 60, 230, 1k, 3.6k.
  String bandLabel(double hz) => hz >= 1000
      ? '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}k'
      : '${hz.round()}';

  /// Name ideas for a new playlist.
  List<String> get playlistNameSuggestions => [
    playlistSuggestionChill,
    playlistSuggestionWorkout,
    playlistSuggestionRoadTrip,
    playlistSuggestionFocus,
    playlistSuggestionLateNight,
  ];

  String videoSkipSeconds(int seconds) => secondsValue(seconds);

  /// +10s / −10s.
  String seekSeconds(int seconds) =>
      seconds > 0 ? seekForward(seconds) : seekBack(-seconds);

  /// 15 min, 1 h, 1 h 30 min.
  String sleepTimerMinutes(int minutes) => minutes >= 60 && minutes % 60 == 0
      ? hoursValue(minutes ~/ 60)
      : minutes > 60
      ? hoursMinutesValue(minutes ~/ 60, minutes % 60)
      : minutesValue(minutes);

  String statsHours(int hours, int minutes) =>
      hours > 0 ? hoursMinutesValue(hours, minutes) : minutesValue(minutes);

  String minimumLengthValue(int seconds) => seconds == 0
      ? anyLength
      : seconds < 60
      ? secondsValue(seconds)
      : minutesValue(seconds ~/ 60);

  String videoLibraryUpdated(int added, int removed) => [
    if (added > 0) videosAdded(added),
    if (removed > 0) videosRemoved(removed),
  ].join(' · ');

  String scanResult({required int added, required int removed}) => [
    if (added > 0) scanFoundSongs(added),
    if (removed > 0) scanRemovedSongs(removed),
  ].join(' · ');

  /// A failure's message ([ErrorMessages]) in this language; any other
  /// message as it is.
  String failure(String message) => switch (message) {
    ErrorMessages.librarySync => errorLibrarySync,
    ErrorMessages.libraryRead => errorLibraryRead,
    ErrorMessages.write => errorWrite,
    ErrorMessages.songsDelete => errorSongsDelete,
    ErrorMessages.libraryPermission => errorLibraryPermission,
    ErrorMessages.videosSync => errorVideosSync,
    ErrorMessages.videosDelete => errorVideosDelete,
    ErrorMessages.videosPermission => errorVideosPermission,
    _ => message,
  };
}

/// A text to show later, in whatever language is in use then (cubits
/// produce these; screens turn them into words).
typedef LocalizedText = String Function(AppLocalizations l10n);
