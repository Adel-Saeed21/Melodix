import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/logic/video_library_cubit.dart';

/// ♥ on a video row: favourites it, or takes it out.
class VideoFavouriteButton extends StatelessWidget {
  const VideoFavouriteButton({super.key, required this.video});

  final Video video;

  @override
  Widget build(BuildContext context) {
    final favourite = video.isFavorite;
    return IconButton(
      tooltip: favourite
          ? AppStrings.removeFromFavourites
          : AppStrings.addToFavourites,
      onPressed: () async {
        // The list updates by itself (it's live).
        final result = await context.read<VideoLibraryCubit>().toggleFavorite(
          video.id,
        );
        if (result == null && context.mounted) {
          AppSnackBar.show(
            context,
            AppStrings.changeNotSaved,
            kind: AppSnackBarKind.error,
          );
        }
      },
      icon: Icon(
        favourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: favourite
            ? Theme.of(context).primaryColor
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}
