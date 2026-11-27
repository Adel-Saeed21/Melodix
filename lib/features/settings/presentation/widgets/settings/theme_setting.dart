import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/widgets/theme_mode_picker.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';

/// Dark / light / the phone's, as the onboarding shows them.
class ThemeSetting extends StatelessWidget {
  const ThemeSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingRow(
      title: context.l10n.theme,
      below: FittedBox(fit: BoxFit.scaleDown, child: ThemeModePicker()),
    );
  }
}
