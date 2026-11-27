import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/service/onboarding_service.dart';
import 'package:melodix/core/widgets/glow_background.dart';
import 'package:melodix/features/onboarding/presentation/widgets/onboarding_illustrations.dart';
import 'package:melodix/core/widgets/theme_mode_picker.dart';
import 'package:melodix/features/onboarding/presentation/widgets/onboarding/onboarding_top_bar.dart';
import 'package:melodix/features/onboarding/presentation/widgets/onboarding/onboarding_slide_view.dart';
import 'package:melodix/features/onboarding/presentation/widgets/onboarding/onboarding_bottom_bar.dart';

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

  static List<OnboardingSlide> _slidesFor(AppLocalizations l10n) => [
    OnboardingSlide(
      l10n.onboardingMusicTitle,
      l10n.onboardingMusicBody,
      (t) => MusicIllustration(time: t),
    ),
    OnboardingSlide(
      l10n.onboardingVideoTitle,
      l10n.onboardingVideoBody,
      (t) => VideoIllustration(time: t),
    ),
    OnboardingSlide(
      l10n.onboardingSubtitlesTitle,
      l10n.onboardingSubtitlesBody,
      (t) => SubtitlesIllustration(time: t),
    ),
    OnboardingSlide(
      l10n.onboardingThemeTitle,
      l10n.onboardingThemeBody,
      (_) => const ThemeModePicker(),
    ),
  ];

  /// The slides' count (the same in every language).
  static final int _count = _slidesFor(const AppLocalizations()).length;

  int get _last => _count - 1;

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
                  OnboardingTopBar(
                    showSkip: _index < _last,
                    onSkip: () => _goTo(_last),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: _count,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => OnboardingSlideView(
                        slide: _slidesFor(context.l10n)[i],
                        index: i,
                        position: _position,
                        time: _time,
                      ),
                    ),
                  ),
                  OnboardingBottomBar(
                    count: _count,
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
