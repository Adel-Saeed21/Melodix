import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';

/// Asks for a playlist name in a bottom sheet that rises with the keyboard.
/// Returns the trimmed name, or null if cancelled.
///
/// Pass [initialName] to rename: the field starts with it selected and the
/// action stays disabled until the name actually changes.
Future<String?> showPlaylistNameDialog(
  BuildContext context, {
  String title = AppStrings.newPlaylist,
  String actionLabel = AppStrings.create,
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
    builder: (_) => _PlaylistNameSheet(
      title: title,
      actionLabel: actionLabel,
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
      title: const Text(AppStrings.deletePlaylist),
      content: Text(AppStrings.deletePlaylistConfirm(name)),
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

class _PlaylistNameSheet extends StatefulWidget {
  const _PlaylistNameSheet({
    required this.title,
    required this.actionLabel,
    required this.initialName,
  });

  final String title;
  final String actionLabel;
  final String initialName;

  bool get isRename => initialName.isNotEmpty;

  @override
  State<_PlaylistNameSheet> createState() => _PlaylistNameSheetState();
}

class _PlaylistNameSheetState extends State<_PlaylistNameSheet> {
  static const int _maxLength = 40;

  late final _controller = TextEditingController(text: widget.initialName)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialName.length,
    );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _canSubmit(String text) {
    final name = text.trim();
    return name.isNotEmpty && name != widget.initialName.trim();
  }

  void _submit() {
    if (!_canSubmit(_controller.text)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  void _useSuggestion(String name) {
    _controller.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.primaryColor;

    return Padding(
      // Rise above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            final canSubmit = _canSubmit(value.text);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CoverPreview(size: 56.r),
                    horizontalSpace(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: onSurface,
                              fontSize: AppTextSizes.xl,
                              fontWeight: FontWeightHelper.bold,
                            ),
                          ),
                          verticalSpace(2),
                          Text(
                            widget.isRename
                                ? AppStrings.renamePlaylistSubtitle
                                : AppStrings.newPlaylistSubtitle,
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.6),
                              fontSize: AppTextSizes.sm,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                verticalSpace(24),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLength: _maxLength,
                  cursorColor: primary,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: TextStyle(
                    color: onSurface,
                    fontSize: AppTextSizes.lg,
                    fontWeight: FontWeightHelper.semiBold,
                  ),
                  decoration: InputDecoration(
                    labelText: AppStrings.playlistName,
                    hintText: AppStrings.playlistNameHint,
                    floatingLabelStyle: TextStyle(color: primary),
                    filled: true,
                    fillColor: onSurface.withValues(alpha: 0.06),
                    prefixIcon: Icon(
                      Icons.edit_rounded,
                      size: 20.r,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: AppStrings.clearName,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20.r,
                              color: onSurface.withValues(alpha: 0.5),
                            ),
                            onPressed: _controller.clear,
                          ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 18.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide(color: primary, width: 1.5),
                    ),
                  ),
                ),
                if (!widget.isRename) ...[
                  verticalSpace(4),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      for (final name in AppStrings.playlistNameSuggestions)
                        _SuggestionChip(
                          label: name,
                          selected: value.text.trim() == name,
                          onTap: () => _useSuggestion(name),
                        ),
                    ],
                  ),
                ],
                verticalSpace(24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: onSurface,
                          side: BorderSide(
                            color: onSurface.withValues(alpha: 0.2),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(AppStrings.cancel),
                      ),
                    ),
                    horizontalSpace(12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canSubmit ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(widget.actionLabel),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A green gradient tile hinting at the playlist cover.
class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withValues(alpha: 0.55)],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.queue_music_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final onSurface = theme.colorScheme.onSurface;

    return Material(
      color: selected
          ? primary.withValues(alpha: 0.16)
          : onSurface.withValues(alpha: 0.06),
      shape: StadiumBorder(
        side: BorderSide(color: selected ? primary : Colors.transparent),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? primary : onSurface.withValues(alpha: 0.8),
              fontSize: AppTextSizes.sm,
              fontWeight: FontWeightHelper.medium,
            ),
          ),
        ),
      ),
    );
  }
}
