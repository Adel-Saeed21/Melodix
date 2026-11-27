import 'package:melodix/core/config/theme/app_accent.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

class FavouritesCollapsedBar extends StatelessWidget {
  const FavouritesCollapsedBar({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AccentColors.favouritesGradient(
            Theme.of(context).primaryColor,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: kToolbarHeight,
          child: Center(
            child: Text(
              context.l10n.favourites,
              style: TextStyle(
                color: Colors.white,
                fontSize: AppTextSizes.lg,
                fontWeight: FontWeightHelper.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
