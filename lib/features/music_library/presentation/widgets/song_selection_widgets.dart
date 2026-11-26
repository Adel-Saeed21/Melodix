import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';

/// Asks before deleting [count] songs from the device. Returns true to go on.
Future<bool> confirmDeleteSongs(BuildContext context, int count) async {
  final error = Theme.of(context).colorScheme.error;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.delete_forever_rounded, color: error),
      title: Text(AppStrings.deleteSongsTitle(count)),
      content: const Text(AppStrings.deleteSongsMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(AppStrings.delete, style: TextStyle(color: error)),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
