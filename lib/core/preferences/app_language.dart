import 'dart:ui';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:melodix/core/l10n/app_localizations.dart';

/// The app's language: the phone's (when supported, else English), or one
/// chosen in Settings.
enum AppLanguage {
  system(null),
  english(Locale('en')),
  arabic(Locale('ar'));

  const AppLanguage(this.locale);

  /// Null: follow the phone.
  final Locale? locale;

  /// The language's own name (the same in every language, so it can be
  /// found whatever the app is showing).
  String? get nativeName => switch (this) {
    system => null,
    english => 'English',
    arabic => 'العربية',
  };
}

/// The chosen [AppLanguage], saved across restarts.
class AppLanguageCubit extends HydratedCubit<AppLanguage> {
  AppLanguageCubit({Locale Function()? deviceLocale})
    : _deviceLocale =
          deviceLocale ?? (() => PlatformDispatcher.instance.locale),
      super(AppLanguage.system);

  final Locale Function() _deviceLocale;

  void choose(AppLanguage language) => emit(language);

  /// The language in use: the chosen one, or the phone's if the app has
  /// it, else English (as the app itself resolves it).
  Locale get resolvedLocale {
    final chosen = state.locale;
    if (chosen != null) return chosen;
    final device = _deviceLocale().languageCode;
    return AppLocalizations.supportedLocales.firstWhere(
      (l) => l.languageCode == device,
      orElse: () => const Locale('en'),
    );
  }

  /// The texts in use, for code with no screen to read them from (e.g.
  /// the media notification's buttons): easy_localization's language,
  /// which follows this choice (see `changeLanguage`).
  AppLocalizations get strings => const AppLocalizations();

  @override
  AppLanguage? fromJson(Map<String, dynamic> json) =>
      AppLanguage.values.where((l) => l.name == json['language']).firstOrNull;

  @override
  Map<String, dynamic>? toJson(AppLanguage state) => {'language': state.name};
}
