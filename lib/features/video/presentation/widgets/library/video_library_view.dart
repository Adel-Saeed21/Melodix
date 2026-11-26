import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/logic/video_library_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_library_empty_view.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_library_header.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_library_list.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_permission_view.dart';

class VideoLibraryView extends StatelessWidget {
  const VideoLibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const VideoLibraryHeader(),
        Expanded(
          child: BlocBuilder<VideoLibraryCubit, VideoLibraryState>(
            buildWhen: (p, c) =>
                p.status != c.status ||
                p.permission != c.permission ||
                // Not for progress (saved every 15 s while a video plays):
                // rows and "Continue watching" follow it themselves.
                p.videos != c.videos ||
                (p.isScanning != c.isScanning && c.videos.isEmpty),
            builder: (context, state) => switch (state.status) {
              VideoLibraryStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              VideoLibraryStatus.permissionRequired => VideoPermissionView(
                permission: state.permission,
              ),
              VideoLibraryStatus.ready when state.videos.isEmpty =>
                VideoLibraryEmptyView(isScanning: state.isScanning),
              VideoLibraryStatus.ready => VideoLibraryList(state: state),
            },
          ),
        ),
      ],
    );
  }
}
