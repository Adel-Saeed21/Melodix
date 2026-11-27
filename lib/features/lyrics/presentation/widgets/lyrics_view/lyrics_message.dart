import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/features/lyrics/presentation/logic/lyrics_cubit.dart';

class LyricsMessage extends StatelessWidget {
  const LyricsMessage({
    super.key,
    required this.icon,
    this.text,
    this.busy = false,
    this.searchOnline = false,
  });

  final IconData icon;
  final String? text;
  final bool busy;
  final bool searchOnline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              SizedBox(
                width: 28.r,
                height: 28.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.primaryColor,
                ),
              )
            else
              Icon(icon, size: 44.r, color: theme.primaryColor),
            if (text case final text?) ...[
              SizedBox(height: 14.h),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.75),
                  fontSize: AppTextSizes.base,
                ),
              ),
            ],
            if (searchOnline) ...[
              SizedBox(height: 16.h),
              FilledButton.icon(
                onPressed: context.read<LyricsCubit>().searchOnline,
                icon: const Icon(Icons.travel_explore_rounded),
                label: Text(context.l10n.lyricsSearchOnline),
              ),
              SizedBox(height: 8.h),
              Text(
                context.l10n.lyricsSearchHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.45),
                  fontSize: AppTextSizes.xs,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
