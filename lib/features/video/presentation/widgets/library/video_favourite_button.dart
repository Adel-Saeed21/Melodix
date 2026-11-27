import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/logic/favorite_videos_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/video_favourite_action.dart';

/// ♥ on a video: favourites it, or takes it out. Shows the app's live
/// favourites, so it's right wherever the change was made.
class VideoFavouriteButton extends StatelessWidget {
  const VideoFavouriteButton({super.key, required this.video, this.color});

  final Video video;

  /// The empty heart's colour (the full one is the app's accent).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final favourite = context.select(
      (FavoriteVideosCubit c) => c.state.ids.contains(video.id),
    );
    return IconButton(
      tooltip: favourite
          ? context.l10n.removeFromFavourites
          : context.l10n.addToFavourites,
      onPressed: () => toggleVideoFavourite(context, video.id),
      icon: Icon(
        favourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: favourite
            ? Theme.of(context).primaryColor
            : color ??
                  Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.5),
      ),
    );
  }
}
