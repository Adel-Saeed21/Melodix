import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/video/presentation/widgets/library/scan_videos.dart';

/// No videos yet: a spinner while the first scan runs, else a message
/// with a scan button.
class VideoLibraryEmptyView extends StatelessWidget {
  const VideoLibraryEmptyView({super.key, required this.isScanning});

  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    if (isScanning) return const Center(child: CircularProgressIndicator());
    return LibraryStatusView(
      icon: Icons.video_library_outlined,
      title: context.l10n.noVideosTitle,
      message: context.l10n.noVideosSubtitle,
      actionLabel: context.l10n.scanVideos,
      onAction: () => scanVideos(context),
    );
  }
}
