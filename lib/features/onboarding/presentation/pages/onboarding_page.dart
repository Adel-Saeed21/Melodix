import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/onboarding_service.dart';
import 'package:melodix/core/widgets/melodix_mark.dart';
import 'package:melodix/core/widgets/glow_background.dart';
import 'package:melodix/features/onboarding/presentation/widgets/onboarding_illustrations.dart';
import 'package:melodix/core/widgets/theme_mode_picker.dart';

/// First launch: what Melodix does, in a few swipes (music, video,
/// subtitles), then the look (dark / light / the phone's). Everything is
/// drawn in code and animated; no images.
///
/// Skip jumps to the look; finishing remembers onboarding is done (see
/// [OnboardingService]) and opens the library.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.onFinished});

  /// What finishing does after saving (default: go to the library).
  final VoidCallback? onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _Slide {
  const _Slide(this.title, this.body, this.illustration);

  final String title;
  final String body;
  final Widget Function(Animation<double> time) illustration;
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pages = PageController();

  /// The page as a fraction while swiping (for parallax and the dots).
  final ValueNotifier<double> _position = ValueNotifier(0);
  late final AnimationController _time = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  int _index = 0;
  bool _finishing = false;

  static final List<_Slide> _slides = [
    _Slide(
      AppStrings.onboardingMusicTitle,
      AppStrings.onboardingMusicBody,
      (t) => MusicIllustration(time: t),
    ),
    _Slide(
      AppStrings.onboardingVideoTitle,
      AppStrings.onboardingVideoBody,
      (t) => VideoIllustration(time: t),
    ),
    _Slide(
      AppStrings.onboardingSubtitlesTitle,
      AppStrings.onboardingSubtitlesBody,
      (t) => SubtitlesIllustration(time: t),
    ),
    _Slide(
      AppStrings.onboardingThemeTitle,
      AppStrings.onboardingThemeBody,
      (_) => const ThemeModePicker(),
    ),
  ];

  int get _last => _slides.length - 1;

  @override
  void initState() {
    super.initState();
    _pages.addListener(() {
      if (_pages.hasClients && _pages.position.haveDimensions) {
        _position.value = _pages.page ?? _index.toDouble();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Remove animations": everything still, in its resting state.
    if (MediaQuery.disableAnimationsOf(context)) {
      _time.stop();
    } else if (!_time.isAnimating) {
      unawaited(_time.repeat());
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _position.dispose();
    _time.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      unawaited(
        _pages.animateToPage(
          page,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await OnboardingService.markCompleted();
    if (!mounted) return;
    final done = widget.onFinished;
    if (done != null) {
      done();
    } else {
      context.go(Routes.homeScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back steps through the pages before leaving.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index > 0) _goTo(_index - 1);
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: GlowBackground(time: _time, progress: _position),
            ),
            SafeArea(
              child: Column(
                children: [
                  _TopBar(showSkip: _index < _last, onSkip: () => _goTo(_last)),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => _SlideView(
                        slide: _slides[i],
                        index: i,
                        position: _position,
                        time: _time,
                      ),
                    ),
                  ),
                  _BottomBar(
                    count: _slides.length,
                    position: _position,
                    isLast: _index == _last,
                    onNext: _index == _last ? _finish : () => _goTo(_index + 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showSkip, required this.onSkip});

  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 12.w, 0),
      child: Row(
        children: [
          MelodixMark(size: 26.r, color: theme.primaryColor),
          SizedBox(width: 10.w),
          Text(
            AppStrings.appName,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeightHelper.bold,
              color: theme.colorScheme.onSurface,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
            opacity: showSkip ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              onPressed: showSkip ? onSkip : null,
              child: Text(
                AppStrings.onboardingSkip,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeightHelper.semiBold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One page: its illustration above, title and text below. While swiping,
/// the illustration slides slower than the page and the text fades: a
/// little depth.
class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.index,
    required this.position,
    required this.time,
  });

  final _Slide slide;
  final int index;
  final ValueListenable<double> position;
  final Animation<double> time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final illustration = slide.illustration(time);
    return LayoutBuilder(
      builder: (context, constraints) => ValueListenableBuilder<double>(
        valueListenable: position,
        child: illustration,
        builder: (context, page, illustration) {
          final offset = (page - index).clamp(-1.0, 1.0);
          final visible = 1 - offset.abs();
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(
              children: [
                Expanded(
                  flex: 6,
                  child: Transform.translate(
                    offset: Offset(offset * constraints.maxWidth * 0.35, 0),
                    child: Transform.scale(
                      scale: 0.85 + 0.15 * visible,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: EdgeInsets.all(40.r),
                            child: illustration,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Opacity(
                    opacity: visible.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 24 * offset.abs()),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28.sp,
                                height: 1.15,
                                fontWeight: FontWeightHelper.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              slide.body,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15.sp,
                                height: 1.5,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The dots (the current one stretched into a pill, following the swipe)
/// and the button: a round arrow that grows into "Start listening" on the
/// last page.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.count,
    required this.position,
    required this.isLast,
    required this.onNext,
  });

  final int count;
  final ValueListenable<double> position;
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final onAccent = theme.colorScheme.onPrimary;
    return Padding(
      padding: EdgeInsets.fromLTRB(28.w, 8.h, 28.w, 24.h),
      child: Row(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: position,
            builder: (context, page, _) => Row(
              children: [
                for (var i = 0; i < count; i++)
                  Builder(
                    builder: (context) {
                      final near = (1 - (page - i).abs()).clamp(0.0, 1.0);
                      return Container(
                        margin: EdgeInsets.only(right: 6.w),
                        width: 8.r + 20.r * near,
                        height: 8.r,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            theme.colorScheme.onSurface.withValues(alpha: 0.25),
                            accent,
                            near,
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // Shrinks rather than overflows (large text, narrow screens).
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _nextButton(accent, onAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextButton(Color accent, Color onAccent) {
    return Semantics(
      button: true,
      label: isLast ? AppStrings.onboardingStart : AppStrings.onboardingNext,
      excludeSemantics: true,
      child: Material(
        color: accent,
        shape: const StadiumBorder(),
        elevation: 6,
        shadowColor: accent.withValues(alpha: 0.5),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onNext,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLast ? 26.w : 18.r,
                vertical: 18.r,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLast) ...[
                    Text(
                      AppStrings.onboardingStart,
                      style: TextStyle(
                        color: onAccent,
                        fontSize: 16.sp,
                        fontWeight: FontWeightHelper.bold,
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Icon(
                    isLast
                        ? Icons.play_arrow_rounded
                        : Icons.arrow_forward_rounded,
                    color: onAccent,
                    size: 24.r,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
