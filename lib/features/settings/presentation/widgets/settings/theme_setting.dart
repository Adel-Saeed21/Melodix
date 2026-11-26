import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/widgets/theme_mode_picker.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';

/// Dark / light / the phone's, as the onboarding shows them.
class ThemeSetting extends StatelessWidget {
  const ThemeSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingRow(
      title: AppStrings.theme,
      below: FittedBox(fit: BoxFit.scaleDown, child: ThemeModePicker()),
    );
  }
}
