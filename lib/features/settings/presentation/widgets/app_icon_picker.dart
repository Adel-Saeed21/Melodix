import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/service/app_icon_service.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/core/widgets/melodix_mark.dart';

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
          return _IconTile(
            icon: icon,
            selected: icons.state == icon,
            onTap: () async {
              if (icons.state == icon) return;
              final ok = await icons.choose(icon);
              if (!context.mounted) return;
              AppSnackBar.show(
                context,
                ok ? AppStrings.appIconChanged : AppStrings.appIconFailed,
                kind: ok ? AppSnackBarKind.success : AppSnackBarKind.error,
              );
            },
          );
        },
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final LauncherIcon icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).primaryColor;
    final classic = icon == LauncherIcon.classic;
    final label = AppStrings.appIconNamed(
      icon.accent?.label ?? AppStrings.appIconClassic,
    );
    final size = 56.r;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(3.r),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: selected ? accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Container(
                width: size - 10.r,
                height: size - 10.r,
                // Classic: white bars on a green circle (the original
                // icon); the others: the mark in colour on dark.
                decoration: classic
                    ? const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor,
                      )
                    : BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        color: AppColors.darkBackground,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                alignment: Alignment.center,
                child: MelodixMark(
                  size: 24.r,
                  color: classic ? Colors.white : icon.accent!.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
