import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/lyrics/domain/entities/lyrics.dart';
import 'package:melodix/features/lyrics/presentation/logic/lyrics_clock.dart';
import 'package:melodix/features/lyrics/presentation/widgets/lyrics_view/lyrics_line_text.dart';
import 'package:melodix/features/lyrics/presentation/widgets/lyrics_view/lyrics_source_row.dart';

class LyricsLines extends StatefulWidget {
  const LyricsLines({super.key, required this.lyrics});

  final Lyrics lyrics;

  @override
  State<LyricsLines> createState() => _LyricsLinesState();
}

class _LyricsLinesState extends State<LyricsLines> {
  late final List<GlobalKey> _keys = [
    for (final _ in widget.lyrics.lines) GlobalKey(),
  ];

  /// The user scrolled: don't pull the view back until a few lines later.
  int? _userScrolledAt;

  late final LyricsClock _clock = context.read<LyricsClock>();

  /// The line being sung, each time it changes (not on every tick).
  late final Stream<int> _lines = _clock.positions
      .map(widget.lyrics.lineAt)
      .distinct();

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
        _userScrolledAt = lyrics.lineAt(_clock.position);
        return false;
      },
      child: StreamBuilder<int>(
        stream: _lines,
        initialData: lyrics.lineAt(_clock.position),
        builder: (context, snapshot) {
          final current = snapshot.requireData;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _follow(current);
          });
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 80.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lyrics.lines.length; i++)
                  LyricsLineText(
                    key: _keys[i],
                    text: lyrics.lines[i].text,
                    state: !lyrics.isSynced
                        ? LyricsLineState.plain
                        : i == current
                        ? LyricsLineState.now
                        : i < current
                        ? LyricsLineState.sung
                        : LyricsLineState.coming,
                    accent: theme.primaryColor,
                    ink: onSurface,
                    onTap: lyrics.lines[i].time == null
                        ? null
                        : () => _clock.seek(lyrics.lines[i].time!),
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
        LyricsSourceRow(lyrics: lyrics),
      ],
    );
  }
}
