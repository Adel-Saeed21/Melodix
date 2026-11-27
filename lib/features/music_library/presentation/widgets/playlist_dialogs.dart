import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_dialogs/playlist_name_sheet.dart';

/// Asks for a playlist name in a bottom sheet that rises with the keyboard.
/// Returns the trimmed name, or null if cancelled.
///
/// Pass [initialName] to rename: the field starts with it selected and the
/// action stays disabled until the name actually changes.
Future<String?> showPlaylistNameDialog(
  BuildContext context, {
  String? title,
  String? actionLabel,
  String initialName = '',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    builder: (_) => PlaylistNameSheet(
      title: title ?? context.l10n.newPlaylist,
      actionLabel: actionLabel ?? context.l10n.create,
      initialName: initialName,
    ),
  );
}

/// Asks the user to confirm deleting [name]. Returns true to delete.
Future<bool> confirmDeletePlaylist(BuildContext context, String name) async {
  final error = Theme.of(context).colorScheme.error;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.deletePlaylist),
      content: Text(context.l10n.deletePlaylistConfirm(name)),
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
