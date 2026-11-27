import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:melodix/core/l10n/app_localizations.dart';

/// The app's languages (easy_localization) around [child]: English and
/// Arabic, from assets/translations, starting in [startLocale]. One set-up
/// for the app and its tests.
class AppTranslations extends StatelessWidget {
  const AppTranslations({
    super.key,
    required this.startLocale,
    required this.child,
    this.assetLoader = const RootBundleAssetLoader(),
  });

  final Locale startLocale;
  final Widget child;

  /// Where the JSON files are read from (tests may read them directly).
  final AssetLoader assetLoader;

  static const String path = 'assets/translations';

  @override
  Widget build(BuildContext context) => EasyLocalization(
    supportedLocales: AppLocalizations.supportedLocales,
    path: path,
    assetLoader: assetLoader,
    fallbackLocale: const Locale('en'),
    // A text missing in Arabic shows in English, never as its key.
    useFallbackTranslations: true,
    startLocale: startLocale,
    // The choice is kept by AppLanguageCubit (it also knows "same as the
    // phone"), not by easy_localization.
    saveLocale: false,
    useOnlyLangCode: true,
    // Arabic's real plural forms (one, two, few, many), not just 1 / other.
    ignorePluralRules: false,
    child: child,
  );
}
