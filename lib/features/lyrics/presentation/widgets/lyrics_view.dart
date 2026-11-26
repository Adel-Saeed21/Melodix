import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/features/lyrics/domain/entities/lyrics.dart';
import 'package:melodix/features/lyrics/presentation/logic/lyrics_cubit.dart';
import 'package:melodix/features/player/domain/entities/playback_progress.dart';
import 'package:melodix/features/player/presentation/logic/playback_progress_cubit.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';

/// The playing song's lyrics, in place of the cover on Now Playing.
/// Synced lyrics follow the song (the line being sung lit and kept in
/// view; tap a line to jump there); plain lyrics scroll freely.
class LyricsView extends StatelessWidget {
  const LyricsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LyricsCubit, LyricsState>(
      builder: (context, state) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (state.status) {
          LyricsStatus.loading || LyricsStatus.searching => _Message(
            key: ValueKey(state.status),
            icon: Icons.lyrics_rounded,
            text: state.status == LyricsStatus.searching
                ? AppStrings.lyricsSearching
                : null,
            busy: true,
          ),
          LyricsStatus.found => _LyricsLines(
            key: ValueKey(state.songId),
            lyrics: state.lyrics!,
          ),
          LyricsStatus.none => _Message(
            key: const ValueKey('none'),
            icon: Icons.lyrics_outlined,
            text: AppStrings.lyricsNone,
            searchOnline: true,
          ),
          LyricsStatus.notFound => _Message(
            key: const ValueKey('notFound'),
            icon: Icons.search_off_rounded,
            text: AppStrings.lyricsNotFound,
          ),
          LyricsStatus.failed => _Message(
            key: const ValueKey('failed'),
            icon: Icons.wifi_off_rounded,
            text: AppStrings.lyricsFailed,
            searchOnline: true,
          ),
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
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
                label: const Text(AppStrings.lyricsSearchOnline),
              ),
              SizedBox(height: 8.h),
              Text(
                AppStrings.lyricsSearchHint,
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

class _LyricsLines extends StatefulWidget {
  const _LyricsLines({super.key, required this.lyrics});

  final Lyrics lyrics;

  @override
  State<_LyricsLines> createState() => _LyricsLinesState();
}

class _LyricsLinesState extends State<_LyricsLines> {
  late final List<GlobalKey> _keys = [
    for (final _ in widget.lyrics.lines) GlobalKey(),
  ];

  /// The user scrolled: don't pull the view back until a few lines later.
  int? _userScrolledAt;

  void _follow(int line) {
    if (line < 0 || line >= _keys.length) return;
    if (_userScrolledAt case final at? when (line - at).abs() < 3) return;
    _userScrolledAt = null;
    final target = _keys[line].currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.4,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = widget.lyrics;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final fade = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Colors.transparent,
        Colors.black,
        Colors.black,
        Colors.transparent,
      ],
      stops: const [0, 0.1, 0.88, 1],
    );
    final list = NotificationListener<UserScrollNotification>(
      onNotification: (_) {
        _userScrolledAt = lyrics.lineAt(
          context.read<PlaybackProgressCubit>().state.position,
        );
        return false;
      },
      child: BlocSelector<PlaybackProgressCubit, PlaybackProgress, int>(
        selector: (p) => lyrics.lineAt(p.position),
        builder: (context, current) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _follow(current);
          });
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 80.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lyrics.lines.length; i++)
                  _Line(
                    key: _keys[i],
                    text: lyrics.lines[i].text,
                    state: !lyrics.isSynced
                        ? _LineState.plain
                        : i == current
                        ? _LineState.now
                        : i < current
                        ? _LineState.sung
                        : _LineState.coming,
                    accent: theme.primaryColor,
                    ink: onSurface,
                    onTap: lyrics.lines[i].time == null
                        ? null
                        : () => context.read<PlayerCubit>().seek(
                            lyrics.lines[i].time!,
                          ),
                  ),
              ],
            ),
          );
        },
      ),
    );
    return Column(
      children: [
        Expanded(
          child: ShaderMask(
            shaderCallback: fade.createShader,
            blendMode: BlendMode.dstIn,
            child: list,
          ),
        ),
        _SourceRow(lyrics: lyrics),
      ],
    );
  }
}

enum _LineState { plain, sung, now, coming }

class _Line extends StatelessWidget {
  const _Line({
    super.key,
    required this.text,
    required this.state,
    required this.accent,
    required this.ink,
    this.onTap,
  });

  final String text;
  final _LineState state;
  final Color accent;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final now = state == _LineState.now;
    final style = TextStyle(
      fontSize: state == _LineState.plain ? 18.sp : 22.sp,
      height: 1.35,
      fontWeight: FontWeightHelper.bold,
      color: switch (state) {
        _LineState.plain => ink.withValues(alpha: 0.85),
        _LineState.now => accent,
        _LineState.sung => ink.withValues(alpha: 0.35),
        _LineState.coming => ink.withValues(alpha: 0.55),
      },
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 7.h, horizontal: 4.w),
        child: AnimatedScale(
          scale: now ? 1.04 : 1,
          alignment: Alignment.centerLeft,
          duration: const Duration(milliseconds: 250),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: style,
            // An instrumental break: a quiet note.
            child: Text(text.isEmpty ? '♪' : text),
          ),
        ),
      ),
    );
  }
}

/// Where the lyrics came from; lyrics from online can be removed (the
/// wrong song's).
class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.lyrics});

  final Lyrics lyrics;

  @override
  Widget build(BuildContext context) {
    final faint = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.45);
    final label = switch (lyrics.source) {
      LyricsSource.embedded => AppStrings.lyricsFromFile,
      LyricsSource.file => AppStrings.lyricsFromLrc,
      LyricsSource.online => AppStrings.lyricsFromOnline,
    };
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(color: faint, fontSize: AppTextSizes.xs),
        ),
        if (lyrics.source == LyricsSource.online)
          TextButton(
            onPressed: context.read<LyricsCubit>().removeSaved,
            child: Text(
              AppStrings.lyricsRemove,
              style: TextStyle(fontSize: AppTextSizes.xs),
            ),
          ),
      ],
    );
  }
}
