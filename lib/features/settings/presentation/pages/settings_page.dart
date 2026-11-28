import 'package:melodix/features/settings/presentation/widgets/settings/language_setting.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/settings/presentation/widgets/feature_rows.dart';
import 'package:melodix/features/settings/presentation/widgets/settings_header.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';
import 'package:melodix/features/settings/presentation/widgets/settings/theme_setting.dart';
import 'package:melodix/features/settings/presentation/widgets/settings/accent_setting.dart';
import 'package:melodix/features/settings/presentation/widgets/settings/music_bar_setting.dart';
import 'package:melodix/features/settings/presentation/widgets/settings/selection_bar_setting.dart';
import 'package:melodix/features/settings/presentation/widgets/settings/video_skip_setting.dart';
import 'package:melodix/features/settings/presentation/widgets/settings/settings_footer.dart';

/// Settings: the app's plain background, a header like the other tabs',
/// and each choice shown as what it looks like (the theme as little
/// phones, the music bar and selection actions drawn). Changes apply at
/// once.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16.w + padding.left,
              padding.top,
              16.w + padding.right,
              padding.bottom + 24.h,
            ),
            sliver: SliverList.list(
              children: [
                SettingsHeader(),
                SettingsSection(
                  icon: Icons.translate_rounded,
                  title: context.l10n.language,
                  children: const [LanguageSetting()],
                ),
                SettingsSection(
                  icon: Icons.palette_outlined,
                  title: context.l10n.appearance,
                  children: [
                    ThemeSetting(),
                    AccentSetting(),
                    NowPlayingBackgroundChoice(),
                    AppIconRow(),
                  ],
                ),
                SettingsSection(
                  icon: Icons.dashboard_customize_outlined,
                  title: context.l10n.layout,
                  children: [MusicBarSetting(), SelectionBarSetting()],
                ),
                SettingsSection(
                  icon: Icons.headphones_outlined,
                  title: context.l10n.playback,
                  children: [
                    SpeedChoice(),
                    SkipSilenceRow(),
                    FadeChoice(),
                    EqualizerRow(),
                    SleepTimerRow(),
                  ],
                ),
                SettingsSection(
                  icon: Icons.smart_display_outlined,
                  title: context.l10n.videoSettings,
                  children: [VideoSkipSetting(), SubtitleStyleChoice()],
                ),
                SettingsSection(
                  icon: Icons.library_music_outlined,
                  title: context.l10n.library,
                  children: [ListeningStatsRow(), LibraryFiltersRow()],
                ),
                SettingsFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
