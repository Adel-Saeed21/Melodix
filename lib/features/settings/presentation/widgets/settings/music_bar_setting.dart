import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/features/settings/presentation/widgets/preview_choices.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';

class MusicBarSetting extends StatelessWidget {
  const MusicBarSetting({super.key});

  static String _hint(MiniPlayerStyle style, AppLocalizations l10n) =>
      switch (style) {
        MiniPlayerStyle.classic => l10n.miniPlayerClassicHint,
        MiniPlayerStyle.capsule => l10n.miniPlayerCapsuleHint,
        MiniPlayerStyle.minimal => l10n.miniPlayerMinimalHint,
      };

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UiPreferencesCubit>();
    final current = preferences.state.miniPlayer;
    return SettingRow(
      title: context.l10n.miniPlayerStyle,
      subtitle: _hint(current, context.l10n),
      below: PreviewChoices<MiniPlayerStyle>(
        value: current,
        onChanged: preferences.setMiniPlayer,
        options: [
          for (final (style, name) in [
            (MiniPlayerStyle.classic, context.l10n.miniPlayerClassic),
            (MiniPlayerStyle.capsule, context.l10n.miniPlayerCapsule),
            (MiniPlayerStyle.minimal, context.l10n.miniPlayerMinimal),
          ])
            PreviewOption(style, name, (_) => MusicBarPreview(style)),
        ],
      ),
    );
  }
}
