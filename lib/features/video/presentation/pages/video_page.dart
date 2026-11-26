import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/widgets/selection/selection_cubit.dart';
import 'package:melodix/features/video/presentation/logic/video_library_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_library_empty_view.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_library_header.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_library_list.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_permission_view.dart';

/// The Video tab: the videos on the phone, newest first, with the ones
/// you started on top ("Continue watching").
class VideoPage extends StatelessWidget {
  const VideoPage({super.key, this.createCubit});

  /// Tests pass their own; otherwise the app's (from get_it).
  final VideoLibraryCubit Function()? createCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              (createCubit?.call() ?? getIt<VideoLibraryCubit>())..start(),
        ),
        // Which videos are selected (multi-select, like songs).
        BlocProvider(create: (_) => SelectionCubit<String>()),
      ],
      child: const Scaffold(
        body: SafeArea(bottom: false, child: _VideoLibraryView()),
      ),
    );
  }
}

class _VideoLibraryView extends StatelessWidget {
  const _VideoLibraryView();

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
