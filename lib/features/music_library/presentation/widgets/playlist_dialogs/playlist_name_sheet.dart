import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_dialogs/playlist_cover_preview.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_dialogs/playlist_suggestion_chip.dart';

class PlaylistNameSheet extends StatefulWidget {
  const PlaylistNameSheet({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.initialName,
  });

  final String title;
  final String actionLabel;
  final String initialName;

  bool get isRename => initialName.isNotEmpty;

  @override
  State<PlaylistNameSheet> createState() => _PlaylistNameSheetState();
}

class _PlaylistNameSheetState extends State<PlaylistNameSheet> {
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
                    PlaylistCoverPreview(size: 56.r),
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
                        PlaylistSuggestionChip(
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
