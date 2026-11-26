import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/widgets/selection/selection_cubit.dart';
import 'package:melodix/features/video/presentation/logic/video_library_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_library_view.dart';

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
        body: SafeArea(bottom: false, child: VideoLibraryView()),
      ),
    );
  }
}
