import 'package:material_ui/material_ui.dart';

import 'package:melodix/features/player/presentation/widgets/mini_player_bar.dart';

/// The frame of an album, artist or playlist page: a see-through app bar
/// and the mini player at the bottom, so playback stays at hand.
class CollectionPageScaffold extends StatelessWidget {
  const CollectionPageScaffold({
    super.key,
    required this.body,
    this.actions,
    this.extendBehindAppBar = false,
  });

  final Widget body;

  /// App bar buttons, e.g. the playlist's ⋮ menu.
  final List<Widget>? actions;

  /// The body starts at the very top, under the app bar (for a full-bleed
  /// header such as [GradientHero]); app bar icons turn white to stay
  /// readable on it.
  final bool extendBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: extendBehindAppBar,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: extendBehindAppBar ? Colors.white : null,
        actions: actions,
      ),
      bottomNavigationBar: const MiniPlayerBar(),
      body: SafeArea(top: false, child: body),
    );
  }
}
