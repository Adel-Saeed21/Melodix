import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/core/widgets/selection/selection_cubit.dart';
import 'package:melodix/core/widgets/selection/selection_widgets.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/logic/favorite_videos_cubit.dart';
import 'package:melodix/features/video/presentation/navigation/video_player_navigation.dart';
import 'package:melodix/features/video/presentation/widgets/video_delete_action.dart';

/// What can be done with the selected videos: play them (as a list),
/// (un)favourite them all, delete them from the phone.
List<BulkAction> videoSelectionActions(
  BuildContext context,
  List<Video> selected, {
  required bool allFavourite,
}) {
  final selection = context.read<SelectionCubit<String>>();
  final ids = [for (final v in selected) v.id];
  return [
    BulkAction(
      icon: Icons.play_arrow_rounded,
      label: AppStrings.play,
      onTap: () {
        openVideoPlayer(context, selected, 0);
        selection.exit();
      },
    ),
    BulkAction(
      icon: allFavourite
          ? Icons.heart_broken_rounded
          : Icons.favorite_border_rounded,
      label: allFavourite ? AppStrings.unfavourite : AppStrings.favourite,
      onTap: () async {
        final messages = AppSnackBarTarget.of(context);
        final saved = await context.read<FavoriteVideosCubit>().setFavorite(
          ids,
          favorite: !allFavourite,
        );
        if (!saved) {
          messages.show(AppStrings.changeNotSaved, kind: AppSnackBarKind.error);
          return;
        }
        selection.exit();
        messages.show(
          allFavourite
              ? AppStrings.removedFromFavourites
              : AppStrings.addedToFavourites,
        );
      },
    ),
    BulkAction(
      icon: Icons.delete_outline_rounded,
      label: AppStrings.delete,
      destructive: true,
      onTap: () async {
        final deleted = await deleteVideosAsking(context, ids);
        if (deleted.isNotEmpty) selection.exit();
      },
    ),
  ];
}
