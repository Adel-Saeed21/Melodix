import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/service/app_icon_service.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/features/settings/presentation/widgets/app_icon_picker/app_icon_tile.dart';

/// The home-screen icons as little app icons, side by side (scrolls
/// sideways); the one on the phone now has a ring.
class AppIconPicker extends StatelessWidget {
  const AppIconPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final icons = context.watch<AppIconCubit>();
    return SizedBox(
      height: 66.r,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: LauncherIcon.values.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.r),
        itemBuilder: (context, i) {
          final icon = LauncherIcon.values[i];
          return AppIconTile(
            icon: icon,
            selected: icons.state == icon,
            onTap: () async {
              if (icons.state == icon) return;
              final ok = await icons.choose(icon);
              if (!context.mounted) return;
              AppSnackBar.show(
                context,
                ok ? context.l10n.appIconChanged : context.l10n.appIconFailed,
                kind: ok ? AppSnackBarKind.success : AppSnackBarKind.error,
              );
            },
          );
        },
      ),
    );
  }
}
