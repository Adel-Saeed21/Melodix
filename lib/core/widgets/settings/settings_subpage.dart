import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

/// A page opened from Settings (equalizer, stats, filters): the app's
/// plain background, a back button and a title, then [children] (usually
/// `SettingsSection`s).
class SettingsSubpage extends StatelessWidget {
  const SettingsSubpage({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeightHelper.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16.w + padding.left,
              0,
              16.w + padding.right,
              padding.bottom + 24.h,
            ),
            sliver: SliverList.list(children: children),
          ),
        ],
      ),
    );
  }
}
