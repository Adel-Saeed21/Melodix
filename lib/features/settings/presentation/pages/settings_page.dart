import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/config/theme/theme_cubit/theme_cubit.dart';
import 'package:melodix/core/service/spacing.dart';

/// Settings tab: theme preference and other app configuration.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final mode = context.watch<ThemeCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        children: [
          Text(
            AppStrings.appearance,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.7),
              fontSize: AppTextSizes.base,
              fontWeight: FontWeightHelper.semiBold,
            ),
          ),
          verticalSpace(12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.wb_sunny_outlined),
                label: Text(AppStrings.lightModeText),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.nightlight_round),
                label: Text(AppStrings.darkModeText),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined),
                label: Text(AppStrings.systemModeText),
              ),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                context.read<ThemeCubit>().updateTheme(selection.first),
          ),
        ],
      ),
    );
  }
}
