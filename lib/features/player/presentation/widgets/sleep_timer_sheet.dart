import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/features/player/presentation/logic/sleep_timer_cubit.dart';

/// Opens the sleep timer choices.
Future<void> showSleepTimerSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<SleepTimerCubit>(),
        child: const SleepTimerSheet(),
      ),
    );

/// The timer running (time left, +5 min, off) and the choices: minutes
/// or the end of the song.
class SleepTimerSheet extends StatelessWidget {
  const SleepTimerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final onSurface = theme.colorScheme.onSurface;
    final timer = context.watch<SleepTimerCubit>();
    final state = timer.state;
    void choose(VoidCallback action) {
      action();
      Navigator.of(context).maybePop();
    }

    return SafeArea(
      // Scrolls when the sheet is short (small phones, large text).
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(20.w, 0, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime_rounded, color: accent),
                SizedBox(width: 10.w),
                Text(
                  context.l10n.sleepTimer,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: AppTextSizes.xl,
                    fontWeight: FontWeightHelper.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              context.l10n.sleepTimerHint,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.6),
                fontSize: AppTextSizes.sm,
              ),
            ),
            if (state.isActive) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.endOfSong
                            ? context.l10n.sleepTimerStopsAtEnd
                            : context.l10n.sleepTimerLeft(
                                formatDuration(state.remaining!),
                              ),
                        style: TextStyle(
                          color: accent,
                          fontSize: AppTextSizes.lg,
                          fontWeight: FontWeightHelper.bold,
                        ),
                      ),
                    ),
                    if (state.remaining != null)
                      TextButton(
                        onPressed: () =>
                            timer.extend(const Duration(minutes: 5)),
                        child: Text(context.l10n.sleepTimerAddFive),
                      ),
                    TextButton(
                      onPressed: () => choose(timer.cancel),
                      child: Text(context.l10n.sleepTimerOff),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16.h),
            Wrap(
              spacing: 8.r,
              runSpacing: 8.r,
              children: [
                for (final minutes in SleepTimerCubit.minuteChoices)
                  ActionChip(
                    label: Text(context.l10n.sleepTimerMinutes(minutes)),
                    onPressed: () =>
                        choose(() => timer.start(Duration(minutes: minutes))),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.music_note_rounded),
                  label: Text(context.l10n.sleepTimerEndOfSong),
                  onPressed: () => choose(timer.stopAtEndOfSong),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
