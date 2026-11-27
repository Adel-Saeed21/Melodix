import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_up_next_sheet/video_up_next_list.dart';

/// The list being played, from the player: the current video marked; tap
/// another to play it.
Future<void> showVideoUpNext(BuildContext context) {
  final cubit = context.read<VideoPlayerCubit>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xF0141414),
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.7,
    ),
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const VideoUpNextList()),
  );
}
