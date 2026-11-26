import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/features/music_library/domain/entities/library_permission.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_status_view.dart';
import 'package:melodix/features/video/presentation/logic/video_library_cubit.dart';

/// Asks for access to the videos: the system dialog, or (once turned off
/// for good) the app's settings page. Nothing is asked until it's tapped.
class VideoPermissionView extends StatelessWidget {
  const VideoPermissionView({super.key, required this.permission});

  final LibraryPermission? permission;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VideoLibraryCubit>();
    final blocked = permission == LibraryPermission.permanentlyDenied;
    return LibraryStatusView(
      icon: Icons.video_library_outlined,
      title: AppStrings.videoPermissionTitle,
      message: blocked
          ? AppStrings.videoPermissionBlockedMessage
          : AppStrings.videoPermissionMessage,
      actionLabel: blocked ? AppStrings.openSettings : AppStrings.allowAccess,
      onAction: blocked ? cubit.openSettings : cubit.requestPermission,
    );
  }
}
