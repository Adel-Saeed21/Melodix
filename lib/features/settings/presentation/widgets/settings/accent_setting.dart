import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/features/settings/presentation/widgets/accent_swatches.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';

class AccentSetting extends StatelessWidget {
  const AccentSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UiPreferencesCubit>();
    final state = preferences.state;
    return SettingRow(
      title: context.l10n.accentColour,
      subtitle: state.dynamicAccent
          ? context.l10n.coverColoursHint
          : state.accent.label,
      below: AccentSwatches(
        value: state.accent,
        fromCover: state.dynamicAccent,
        onChanged: preferences.setAccent,
        onFromCover: () => preferences.setDynamicAccent(true),
      ),
    );
  }
}
