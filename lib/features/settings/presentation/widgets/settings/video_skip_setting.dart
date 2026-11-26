import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/features/settings/presentation/widgets/pill_choices.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';

/// How far the video player's skip buttons and double-taps jump.
class VideoSkipSetting extends StatelessWidget {
  const VideoSkipSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UiPreferencesCubit>();
    return SettingRow(
      title: AppStrings.videoSkip,
      subtitle: AppStrings.videoSkipHint,
      below: PillChoices<int>(
        value: preferences.state.videoSeekSeconds,
        onChanged: preferences.setVideoSeekSeconds,
        options: [
          for (final seconds in UiPreferences.videoSeekChoices)
            (seconds, AppStrings.videoSkipSeconds(seconds)),
        ],
      ),
    );
  }
}
