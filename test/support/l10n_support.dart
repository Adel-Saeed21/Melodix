// Test-only access to easy_localization's store: its `Localization` and
// `Translations` aren't exported, and tests need to load a language
// without the app's widget (and switch it within a test).
// ignore_for_file: implementation_imports
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/widgets.dart';
import 'package:melodix/core/l10n/app_translations.dart';
import 'package:melodix/core/l10n/l10n.dart';

/// The app's texts in the tests' language: English, loaded for every test
/// by flutter_test_config.dart (unless a test switches with [useLanguage]).
const english = AppLocalizations();

Map<String, dynamic> readTranslations(String language) =>
    jsonDecode(
          File('${AppTranslations.path}/$language.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

/// Makes [language] ('en' or 'ar') the one texts are read in, as the app
/// would (real plural rules, English for anything missing).
void useLanguage(String language) => Localization.load(
  Locale(language),
  translations: Translations(readTranslations(language)),
  fallbackTranslations: Translations(readTranslations('en')),
  ignorePluralRules: false,
);

/// Reads the translation files straight from disk (no asset bundle in
/// plain tests), for `AppTranslations(assetLoader: …)`.
class FileTranslationsLoader extends AssetLoader {
  const FileTranslationsLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      readTranslations(locale.languageCode);
}
