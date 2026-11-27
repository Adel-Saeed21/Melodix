import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';

/// The rounded search field shown in place of the Music title. The ✕ closes
/// search (it doesn't just clear the text).
class LibrarySearchField extends StatelessWidget {
  const LibrarySearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClose,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  /// The keyboard's search key.
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.primaryColor;
    final radius = BorderRadius.circular(30.r);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      cursorColor: primary,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: onSurface, fontSize: AppTextSizes.base),
      decoration: InputDecoration(
        hintText: AppStrings.searchHint,
        hintStyle: TextStyle(
          color: onSurface.withValues(alpha: 0.45),
          fontSize: AppTextSizes.base,
        ),
        filled: true,
        fillColor: onSurface.withValues(alpha: 0.07),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 14.h),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: onSurface.withValues(alpha: 0.6),
        ),
        suffixIcon: IconButton(
          tooltip: AppStrings.closeSearch,
          onPressed: onClose,
          icon: Icon(
            Icons.close_rounded,
            color: onSurface.withValues(alpha: 0.7),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}
