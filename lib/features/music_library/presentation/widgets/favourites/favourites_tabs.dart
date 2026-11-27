import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

class FavouritesTabs extends StatelessWidget {
  const FavouritesTabs({super.key});

  static const List<Widget> _tabs = [
    Tab(icon: Icon(Icons.music_note_rounded), text: AppStrings.songs),
    Tab(icon: Icon(Icons.movie_rounded), text: AppStrings.videos),
  ];

  /// The tabs' height (fixed by Material: it doesn't grow with text size).
  static double get height => const TabBar(tabs: _tabs).preferredSize.height;

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
        tabs: _tabs,
      ),
    );
  }
}
