import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/features/player/domain/entities/equalizer_preset.dart';
import 'package:melodix/features/player/presentation/logic/audio_settings_cubit.dart';
import 'package:melodix/features/settings/presentation/widgets/settings_section.dart';
import 'package:melodix/features/settings/presentation/widgets/settings_subpage.dart';

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
      title: AppStrings.equalizer,
      children: [
        if (!supported)
          const SettingsSection(
            icon: Icons.info_outline_rounded,
            title: AppStrings.equalizer,
            children: [SettingRow(title: AppStrings.equalizerUnsupported)],
          )
        else ...[
          SettingsSection(
            icon: Icons.graphic_eq_rounded,
            title: state.preset.label,
            children: [
              SwitchListTile(
                title: const Text(AppStrings.equalizerOn),
                value: state.equalizerOn,
                onChanged: settings.setEqualizerOn,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: state.equalizerOn ? 1 : 0.45,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 70.h,
                        child: _Curve(gains: state.gains),
                      ),
                      SizedBox(height: 8.h),
                      SizedBox(
                        height: 220.h,
                        child: Row(
                          children: [
                            for (var i = 0; i < equalizerBandsHz.length; i++)
                              Expanded(
                                child: _Band(
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
                        AppStrings.equalizerBars,
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
            title: AppStrings.equalizerPresets,
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

/// One band: its dB above, a vertical slider, its frequency below.
class _Band extends StatelessWidget {
  const _Band({required this.hz, required this.db, required this.onChanged});

  final double hz;
  final double db;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final faint = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final label = '${db > 0 ? '+' : ''}${db.round()}';
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTextSizes.xs,
            fontWeight: FontWeightHelper.bold,
            color: db == 0 ? faint : theme.primaryColor,
          ),
        ),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                activeTrackColor: theme.primaryColor,
                inactiveTrackColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.12,
                ),
                thumbColor: theme.primaryColor,
              ),
              child: Semantics(
                label: '${AppStrings.bandLabel(hz)} Hz',
                child: Slider(
                  value: db,
                  min: -equalizerMaxGainDb,
                  max: equalizerMaxGainDb,
                  divisions: (equalizerMaxGainDb * 2).round(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ),
        Text(
          AppStrings.bandLabel(hz),
          style: TextStyle(fontSize: AppTextSizes.xs, color: faint),
        ),
      ],
    );
  }
}

/// The sound's shape: a smooth line through the bands, filled with the
/// accent below it, a faint 0 dB line across.
class _Curve extends StatelessWidget {
  const _Curve({required this.gains});

  final List<double> gains;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _CurvePainter(
        gains: gains,
        accent: theme.primaryColor,
        ink: theme.colorScheme.onSurface,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({required this.gains, required this.accent, required this.ink});

  final List<double> gains;
  final Color accent;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    canvas.drawLine(
      Offset(0, mid),
      Offset(size.width, mid),
      Paint()
        ..color = ink.withValues(alpha: 0.12)
        ..strokeWidth = 1,
    );
    final low = math.log(equalizerBandsHz.first / 1.6);
    final high = math.log(equalizerBandsHz.last * 1.4);
    final path = Path();
    const steps = 64;
    for (var i = 0; i <= steps; i++) {
      final x = size.width * i / steps;
      final hz = math.exp(low + (high - low) * i / steps);
      final db = gainAt(hz, gains);
      final y = mid - db / equalizerMaxGainDb * (size.height / 2 - 4);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas
      ..drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withValues(alpha: 0.35),
              accent.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      )
      ..drawPath(
        path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.accent != accent || old.ink != ink || !identical(old.gains, gains);
}
