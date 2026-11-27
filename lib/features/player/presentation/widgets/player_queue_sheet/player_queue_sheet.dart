import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/player/presentation/widgets/player_queue_sheet/player_queue_list.dart';

class PlayerQueueSheet extends StatelessWidget {
  const PlayerQueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) =>
          BlocBuilder<PlayerCubit, NowPlaying>(
            buildWhen: (p, c) =>
                p.queue != c.queue ||
                p.currentIndex != c.currentIndex ||
                p.isPlaying != c.isPlaying ||
                p.queueTitle != c.queueTitle,
            builder: (context, state) => PlayerQueueList(
              state: state,
              scrollController: scrollController,
            ),
          ),
    );
  }
}
