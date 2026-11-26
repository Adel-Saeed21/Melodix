import 'dart:math' as math;

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/widgets/melodix_mark.dart';

/// A frosted rounded card the illustrations are drawn on.
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.width, this.height});

  final Widget child;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Music: the Melodix bars dancing like an equalizer, notes floating
/// around, and a "now playing" pill.
class MusicIllustration extends StatelessWidget {
  const MusicIllustration({super.key, required this.time});

  final Animation<double> time;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).primaryColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return AnimatedBuilder(
      animation: time,
      builder: (context, _) {
        final t = time.value * 2 * math.pi;
        final levels = [
          for (var i = 0; i < 5; i++)
            0.45 + 0.5 * math.sin(t * 3 + i * 1.3).abs(),
        ];
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _GlassCard(
              width: 230.r,
              height: 230.r,
              child: Center(
                child: MelodixMark(size: 130.r, color: accent, levels: levels),
              ),
            ),
            for (var i = 0; i < 4; i++)
              _orbiting(
                t + i * math.pi / 2,
                150.r,
                Icon(
                  i.isEven
                      ? Icons.music_note_rounded
                      : Icons.queue_music_rounded,
                  color: (i.isEven ? accent : onSurface).withValues(alpha: 0.8),
                  size: (i.isEven ? 30 : 24).r,
                ),
              ),
            Positioned(
              bottom: -10.r,
              child: _NowPlayingPill(progress: time.value),
            ),
          ],
        );
      },
    );
  }

  static Widget _orbiting(double angle, double radius, Widget child) =>
      Transform.translate(
        offset: Offset(
          math.cos(angle) * radius,
          math.sin(angle) * radius * 0.7,
        ),
        child: child,
      );
}

class _NowPlayingPill extends StatelessWidget {
  const _NowPlayingPill({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    return Container(
      width: 200.r,
      padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 10.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30.r,
            height: 30.r,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.5)],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(width: 10.r),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _line(context, 0.8),
                SizedBox(height: 6.r),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    color: accent,
                    backgroundColor: accent.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.r),
          Icon(Icons.pause_rounded, color: accent, size: 22.r),
        ],
      ),
    );
  }
}

Widget _line(BuildContext context, double widthFactor, {double alpha = 0.5}) =>
    FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface
              .withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );

/// A video screen with a play button and a moving progress bar, and a
/// floating small window bobbing at its corner.
class VideoIllustration extends StatelessWidget {
  const VideoIllustration({super.key, required this.time});

  final Animation<double> time;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).primaryColor;
    return AnimatedBuilder(
      animation: time,
      builder: (context, _) {
        final t = time.value * 2 * math.pi;
        final bubble = (time.value * 2) % 1; // twice a loop
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _GlassCard(
              width: 270.r,
              height: 170.r,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: 0.55),
                            const Color(0xFF1B1B2F),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 56.r,
                        height: 56.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: accent,
                          size: 36.r,
                        ),
                      ),
                    ),
                    // "+10s", rising and fading.
                    Positioned(
                      right: 24.r,
                      top: 60.r - bubble * 30.r,
                      child: Opacity(
                        opacity: (1 - bubble).clamp(0, 1),
                        child: Text(
                          AppStrings.seekSeconds(10),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeightHelper.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16.r,
                      right: 16.r,
                      bottom: 14.r,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: time.value,
                          minHeight: 4,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // The small window, floating over "other apps".
            Positioned(
              right: -18.r,
              bottom: -40.r + math.sin(t) * 8.r,
              child: Container(
                width: 110.r,
                height: 66.r,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: accent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.picture_in_picture_alt_rounded,
                  color: Colors.white,
                  size: 24.r,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A screen with captions changing at the bottom, a CC badge and an
/// "offline" badge.
class SubtitlesIllustration extends StatelessWidget {
  const SubtitlesIllustration({super.key, required this.time});

  final Animation<double> time;

  static const List<String> captions = [
    AppStrings.onboardingCaption1,
    AppStrings.onboardingCaption2,
    AppStrings.onboardingCaption3,
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).primaryColor;
    return AnimatedBuilder(
      animation: time,
      builder: (context, _) {
        final index = (time.value * captions.length).floor() % captions.length;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _GlassCard(
              width: 270.r,
              height: 170.r,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF2A2A3E), Color(0xFF101018)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 18.r,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween(
                                    begin: const Offset(0, 0.4),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: Container(
                            key: ValueKey(index),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.r,
                              vertical: 4.r,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              captions[index],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeightHelper.medium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -16.r,
              left: -10.r,
              child: _Badge(
                icon: Icons.closed_caption_rounded,
                label: 'SRT · VTT',
                color: accent,
              ),
            ),
            Positioned(
              bottom: -18.r,
              right: -6.r,
              child: _Badge(
                icon: Icons.cloud_off_rounded,
                label: AppStrings.onboardingOffline,
                color: accent,
                filled: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = filled ? Colors.white : color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
      decoration: BoxDecoration(
        color: filled ? color : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 18.r),
          SizedBox(width: 6.r),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeightHelper.bold,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
