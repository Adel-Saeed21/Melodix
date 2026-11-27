import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/features/player/domain/entities/equalizer_preset.dart';
import 'package:melodix/features/player/presentation/logic/audio_settings_cubit.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';
import 'package:melodix/core/widgets/settings/settings_subpage.dart';
import 'package:melodix/features/player/presentation/widgets/equalizer/equalizer_band.dart';
import 'package:melodix/features/player/presentation/widgets/equalizer/equalizer_curve.dart';

/// The equalizer: on / off, the sound's shape as a curve, five bars to
/// drag and presets. Changes are heard at once.
class EqualizerPage extends StatelessWidget {
  const EqualizerPage({super.key, required this.supported});

  /// False where the phone has no equalizer: only a note shows.
  final bool supported;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AudioSettingsCubit>();
    final state = settings.state;
    return SettingsSubpage(
      title: context.l10n.equalizer,
      children: [
        if (!supported)
          SettingsSection(
            icon: Icons.info_outline_rounded,
            title: context.l10n.equalizer,
            children: [SettingRow(title: context.l10n.equalizerUnsupported)],
          )
        else ...[
          SettingsSection(
            icon: Icons.graphic_eq_rounded,
            title: state.preset.label,
            children: [
              SwitchListTile(
                title: Text(context.l10n.equalizerOn),
                value: state.equalizerOn,
                onChanged: settings.setEqualizerOn,
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.w, 4.h, 16.w, 16.h),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: state.equalizerOn ? 1 : 0.45,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 70.h,
                        child: EqualizerCurve(gains: state.gains),
                      ),
                      SizedBox(height: 8.h),
                      SizedBox(
                        height: 220.h,
                        child: Row(
                          children: [
                            for (var i = 0; i < equalizerBandsHz.length; i++)
                              Expanded(
                                child: EqualizerBand(
                                  hz: equalizerBandsHz[i],
                                  db: state.gains[i],
                                  onChanged: (db) => settings.setBand(i, db),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        context.l10n.equalizerBars,
                        style: TextStyle(
                          fontSize: AppTextSizes.xs,
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SettingsSection(
            icon: Icons.tune_rounded,
            title: context.l10n.equalizerPresets,
            children: [
              Padding(
                padding: EdgeInsets.all(14.r),
                child: Wrap(
                  spacing: 8.r,
                  runSpacing: 8.r,
                  children: [
                    for (final preset in EqualizerPreset.values)
                      if (preset != EqualizerPreset.custom ||
                          state.preset == EqualizerPreset.custom)
                        ChoiceChip(
                          label: Text(preset.label),
                          selected: state.preset == preset,
                          onSelected: (_) => settings.setPreset(preset),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
