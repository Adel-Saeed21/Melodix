import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

class FavouritesTabs extends StatelessWidget {
  const FavouritesTabs({super.key});

  static List<Widget> _tabs(AppLocalizations l10n) => [
    Tab(icon: const Icon(Icons.music_note_rounded), text: l10n.songs),
    Tab(icon: const Icon(Icons.movie_rounded), text: l10n.videos),
  ];

  /// The tabs' height (fixed by Material: it doesn't grow with text size,
  /// nor change with the language).
  static double get height => TabBar(tabs: _tabs(const AppLocalizations())).preferredSize.height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: TabBar(
        dividerColor: onSurface.withValues(alpha: 0.08),
        indicatorColor: theme.primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: onSurface,
        unselectedLabelColor: onSurface.withValues(alpha: 0.5),
        labelStyle: TextStyle(
          fontSize: AppTextSizes.lg,
          fontWeight: FontWeightHelper.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: AppTextSizes.lg,
          fontWeight: FontWeightHelper.medium,
        ),
        tabs: _tabs(context.l10n),
      ),
    );
  }
}
