import 'package:melodix/core/service/system_delete_confirmation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/features/video/domain/usecases/video_bulk_usecases.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';

/// Deletes videos from the phone, the same way everywhere (a row's ⋮, a
/// selection): asks first; the system may ask again (Android 11+) and only
/// what was really deleted leaves the lists; a deleted video that's playing
/// stops; says how it went. Returns the ids deleted (none if not).
Future<List<String>> deleteVideosAsking(
  BuildContext context,
  List<String> videoIds,
) async {
  final delete = context.read<DeleteVideosUseCase>();
  final session = context.read<VideoPlayerCubit>();
  final messages = AppSnackBarTarget.of(context);
  final l10n = context.l10n; // read before the awaits below
  if (!await confirmDeleteVideos(context, videoIds.length)) return const [];

  final result = await delete(videoIds);
  return result.fold(
    (failure) {
      messages.show(l10n.failure(failure.message), kind: AppSnackBarKind.error);
      return const [];
    },
    (deleted) {
      if (deleted.isEmpty) {
        messages.show(l10n.videosNotDeleted);
        return const [];
      }
      if (session.state.isActive && deleted.contains(session.state.video.id)) {
        session.stop();
      }
      messages.show(l10n.videosDeleted(deleted.length));
      return deleted;
    },
  );
}

/// Asks before deleting [count] videos from the phone, unless the phone
/// asks itself (see [SystemDeleteConfirmation]). True to go on.
Future<bool> confirmDeleteVideos(BuildContext context, int count) async {
  // Android 11+ asks the user itself: a second dialog would ask twice.
  if (await SystemDeleteConfirmation.asks()) return true;
  if (!context.mounted) return false;
  final error = Theme.of(context).colorScheme.error;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.delete_forever_rounded, color: error),
      title: Text(context.l10n.deleteVideosTitle(count)),
      content: Text(context.l10n.deleteVideosMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(context.l10n.delete, style: TextStyle(color: error)),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
