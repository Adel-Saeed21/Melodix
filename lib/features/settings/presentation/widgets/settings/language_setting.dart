import 'package:melodix/core/l10n/language_switcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/preferences/app_language.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';
import 'package:melodix/features/settings/presentation/widgets/pill_choices.dart';

/// The app's language: the phone's, English or Arabic. Each language is
/// named in itself, so it can be found whatever the app is showing.
class LanguageSetting extends StatelessWidget {
  const LanguageSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguageCubit>();
    return SettingRow(
      title: context.l10n.language,
      subtitle: context.l10n.languageHint,
      below: PillChoices<AppLanguage>(
        value: language.state,
        onChanged: (choice) => LanguageSwitcher.change(context, choice),
        options: [
          for (final choice in AppLanguage.values)
            (choice, choice.nativeName ?? context.l10n.themeSystem),
        ],
      ),
    );
  }
}
