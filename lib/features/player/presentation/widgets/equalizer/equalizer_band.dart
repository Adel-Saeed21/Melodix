import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/features/player/domain/entities/equalizer_preset.dart';

/// One band: its dB above, a vertical slider, its frequency below.
class EqualizerBand extends StatelessWidget {
  const EqualizerBand({
    super.key,
    required this.hz,
    required this.db,
    required this.onChanged,
  });

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
