import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/music_library/presentation/widgets/favourites/favourites_collapsed_bar.dart';
import 'package:melodix/features/music_library/presentation/widgets/favourites/favourites_hero.dart';
import 'package:melodix/features/music_library/presentation/widgets/favourites/favourites_tabs.dart';

/// The hero over the tabs. As it shrinks, the hero slides up out of view
/// and a solid gradient bar (with the title) fades in behind the app bar.
class FavouritesCollapsingHeader extends StatelessWidget {
  const FavouritesCollapsingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // Status bar + app bar (the body extends behind the app bar).
    final barHeight = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 0 while the hero has room for itself (the bar's height is
              // the lowest it can go), 1 once only the bar is left.
              final room = constraints.maxHeight - barHeight;
              final collapsed = (1 - room / (barHeight * 1.5)).clamp(0.0, 1.0);
              return ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const OverflowBox(
                      alignment: Alignment.bottomCenter,
                      maxHeight: double.infinity,
                      child: FavouritesHero(),
                    ),
                    if (collapsed > 0)
                      Opacity(
                        opacity: collapsed,
                        child: const FavouritesCollapsedBar(),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const FavouritesTabs(),
      ],
    );
  }
}
