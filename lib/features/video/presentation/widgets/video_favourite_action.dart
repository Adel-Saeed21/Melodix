import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/features/video/presentation/logic/favorite_videos_cubit.dart';

/// ♥ / un-♥ a video, with the same feedback everywhere (Videos tab,
/// Favourites, player): what happened, with Undo; or that it failed.
///
/// The message shows even if the widget that asked is gone by then (e.g.
/// a row that left the Favourites list).
Future<void> toggleVideoFavourite(BuildContext context, String videoId) async {
  final favourites = context.read<FavoriteVideosCubit>();
  final messages = AppSnackBarTarget.of(context);
  final isFavourite = await favourites.toggleFavorite(videoId);
  if (isFavourite == null) {
    messages.show(AppStrings.changeNotSaved, kind: AppSnackBarKind.error);
    return;
  }
  messages.show(
    isFavourite
        ? AppStrings.addedToFavourites
        : AppStrings.removedFromFavourites,
    actionLabel: AppStrings.undo,
    onAction: () => favourites.toggleFavorite(videoId),
  );
}
