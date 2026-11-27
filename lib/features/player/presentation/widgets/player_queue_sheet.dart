import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/player/presentation/widgets/player_queue_sheet/player_queue_sheet.dart';

/// Shows the songs the current one is playing from ("Playing from …"),
/// highlighting the current song. Tapping a song jumps to it.
Future<void> showPlayerQueue(BuildContext context) {
  final cubit = context.read<PlayerCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const PlayerQueueSheet()),
  );
}
