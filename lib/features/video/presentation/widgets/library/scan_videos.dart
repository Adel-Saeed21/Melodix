import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/features/video/presentation/logic/video_library_cubit.dart';

/// Scans from the user's tap, and says what it found.
Future<void> scanVideos(BuildContext context) async {
  final result = await context.read<VideoLibraryCubit>().scan();
  if (result == null || !context.mounted) return;
  result.fold(
    (failure) {
      if (failure is PermissionFailure) return; // the page says so
      AppSnackBar.show(
        context,
        AppStrings.videoScanFailed,
        kind: AppSnackBarKind.error,
      );
    },
    (changes) => AppSnackBar.show(
      context,
      changes.added == 0 && changes.removed == 0
          ? AppStrings.videosUpToDate
          : AppStrings.videoLibraryUpdated(changes.added, changes.removed),
    ),
  );
}
