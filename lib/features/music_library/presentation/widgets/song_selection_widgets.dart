import 'package:melodix/core/service/system_delete_confirmation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';

/// Asks before deleting [count] songs from the device, unless the phone
/// asks itself (see [SystemDeleteConfirmation]). Returns true to go on.
Future<bool> confirmDeleteSongs(BuildContext context, int count) async {
  // Android 11+ asks the user itself: a second dialog would ask twice.
  if (await SystemDeleteConfirmation.asks()) return true;
  if (!context.mounted) return false;
  final error = Theme.of(context).colorScheme.error;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.delete_forever_rounded, color: error),
      title: Text(context.l10n.deleteSongsTitle(count)),
      content: Text(context.l10n.deleteSongsMessage),
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
