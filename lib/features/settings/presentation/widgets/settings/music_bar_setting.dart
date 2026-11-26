import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/features/settings/presentation/widgets/preview_choices.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';

class MusicBarSetting extends StatelessWidget {
  const MusicBarSetting({super.key});

  static const _hints = {
    MiniPlayerStyle.classic: AppStrings.miniPlayerClassicHint,
    MiniPlayerStyle.capsule: AppStrings.miniPlayerCapsuleHint,
    MiniPlayerStyle.minimal: AppStrings.miniPlayerMinimalHint,
  };

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UiPreferencesCubit>();
    final current = preferences.state.miniPlayer;
    return SettingRow(
      title: AppStrings.miniPlayerStyle,
      subtitle: _hints[current],
      below: PreviewChoices<MiniPlayerStyle>(
        value: current,
        onChanged: preferences.setMiniPlayer,
        options: [
          for (final (style, name) in const [
            (MiniPlayerStyle.classic, AppStrings.miniPlayerClassic),
            (MiniPlayerStyle.capsule, AppStrings.miniPlayerCapsule),
            (MiniPlayerStyle.minimal, AppStrings.miniPlayerMinimal),
          ])
            PreviewOption(style, name, (_) => MusicBarPreview(style)),
        ],
      ),
    );
  }
}
