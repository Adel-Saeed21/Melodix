import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_player_controls.dart';

/// Back, the title, playback speed and ♥.
class VideoTopBar extends StatelessWidget {
  const VideoTopBar({super.key, required this.onTouched});

  final VoidCallback onTouched;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VideoPlayerCubit>();
    return BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
      buildWhen: (p, c) => p.video != c.video || p.speed != c.speed,
      builder: (context, state) => Row(
        children: [
          const BackButton(color: Colors.white),
          Expanded(
            child: Text(
              state.video.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: AppTextSizes.base,
                fontWeight: FontWeightHelper.semiBold,
              ),
            ),
          ),
          PopupMenuButton<double>(
            tooltip: AppStrings.playbackSpeed,
            initialValue: state.speed,
            onOpened: onTouched,
            onSelected: cubit.setSpeed,
            itemBuilder: (_) => [
              for (final speed in VideoPlayerControls.speeds)
                PopupMenuItem(value: speed, child: Text(_speedLabel(speed))),
            ],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              child: Text(
                _speedLabel(state.speed),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppTextSizes.sm,
                  fontWeight: FontWeightHelper.bold,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: state.video.isFavorite
                ? AppStrings.removeFromFavourites
                : AppStrings.addToFavourites,
            onPressed: () async {
              onTouched();
              final isFavorite = await cubit.toggleFavorite();
              if (!context.mounted) return;
              AppSnackBar.show(
                context,
                isFavorite == null
                    ? AppStrings.changeNotSaved
                    : isFavorite
                    ? AppStrings.addedToFavourites
                    : AppStrings.removedFromFavourites,
                kind: isFavorite == null
                    ? AppSnackBarKind.error
                    : AppSnackBarKind.success,
              );
            },
            icon: Icon(
              state.video.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: state.video.isFavorite
                  ? Theme.of(context).primaryColor
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  static String _speedLabel(double speed) {
    final text = speed == speed.roundToDouble()
        ? speed.toStringAsFixed(0)
        : speed.toString();
    return '${text}x';
  }
}
