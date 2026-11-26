import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/features/settings/presentation/widgets/preview_choices.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';

class SelectionBarSetting extends StatelessWidget {
  const SelectionBarSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UiPreferencesCubit>();
    return SettingRow(
      title: AppStrings.selectionBarStyle,
      subtitle: AppStrings.selectionBarHint,
      below: PreviewChoices<SelectionBarStyle>(
        value: preferences.state.selectionBar,
        onChanged: preferences.setSelectionBar,
        options: [
          for (final (style, name) in const [
            (SelectionBarStyle.bottom, AppStrings.selectionBarBottom),
            (SelectionBarStyle.side, AppStrings.selectionBarSide),
          ])
            PreviewOption(style, name, (_) => SelectionBarPreview(style)),
        ],
      ),
    );
  }
}
