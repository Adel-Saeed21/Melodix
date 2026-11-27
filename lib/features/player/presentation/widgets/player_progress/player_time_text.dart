import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/features/player/presentation/widgets/player_progress.dart';

class PlayerTimeText extends StatelessWidget {
  const PlayerTimeText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return FixedSizeTimeText(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        fontSize: AppTextSizes.sm,
      ),
    );
  }
}
