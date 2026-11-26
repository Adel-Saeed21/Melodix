import 'package:material_ui/material_ui.dart';

import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/features/player/presentation/widgets/mini_player.dart';

/// The mini player as a page's bottom bar (for pages opened on top of the
/// home screen, such as album / artist / playlist), kept clear of the system
/// navigation area. Same player state as everywhere else.
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: MiniPlayer(onExpand: () => context.pushNamed(Routes.nowPlaying)),
      ),
    );
  }
}
