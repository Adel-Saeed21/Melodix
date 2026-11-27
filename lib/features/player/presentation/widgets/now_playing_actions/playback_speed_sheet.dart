import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/features/player/presentation/logic/audio_settings_cubit.dart';

class PlaybackSpeedSheet extends StatelessWidget {
  const PlaybackSpeedSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AudioSettingsCubit>();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(20.w, 0, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.speed,
              style: TextStyle(
                color: onSurface,
                fontSize: AppTextSizes.xl,
                fontWeight: FontWeightHelper.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.r,
              runSpacing: 8.r,
              children: [
                for (final speed in AudioSettings.speeds)
                  ChoiceChip(
                    label: Text(context.l10n.speedValue(speed)),
                    selected: settings.state.speed == speed,
                    onSelected: (_) => settings.setSpeed(speed),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.skipSilence),
              subtitle: Text(context.l10n.skipSilenceHint),
              value: settings.state.skipSilence,
              onChanged: settings.setSkipSilence,
            ),
          ],
        ),
      ),
    );
  }
}
