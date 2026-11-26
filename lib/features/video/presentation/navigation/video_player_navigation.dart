import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';

/// Plays [videos] from [index] in the app's video session and shows the
/// full-screen player (next / previous move through [videos]).
void openVideoPlayer(BuildContext context, List<Video> videos, int index) {
  final session = context.read<VideoPlayerCubit>();
  unawaited(session.open(videos, index));
  showVideoPlayer(context);
}

/// Shows the full-screen player (if it isn't already).
void showVideoPlayer(BuildContext context) {
  if (!context.read<VideoPlayerCubit>().state.expanded) {
    unawaited(context.pushNamed<void>(Routes.videoPlayer));
  }
}
