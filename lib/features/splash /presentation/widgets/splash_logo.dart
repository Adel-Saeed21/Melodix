import 'package:material_ui/material_ui.dart';

import 'package:flutter_svg/svg.dart';
import 'package:melodix/core/config/assets/app_vector.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/features/splash /presentation/services/splash_logo_animation_service.dart';

/// The splash logo with subtle polish: a soft green halo that fades in and
/// gently breathes, one light sheen across the logo, and the wordmark rising
/// in below it. The motion is driven by [SplashLogoAnimationService].
///
/// The logo itself is drawn at exactly [logoSize] in the centre from the
/// first frame, matching the native splash, so the hand-off is seamless.
/// With "remove animations" enabled the final state is shown without motion.
class SplashLogo extends StatefulWidget {
  const SplashLogo({super.key, this.wordmarkColor});

  /// Same as the native splash logo: 480 px at 4x.
  static const double logoSize = 120;

  final Color? wordmarkColor;

  @override
  State<SplashLogo> createState() => _SplashLogoState();
}

class _SplashLogoState extends State<SplashLogo> with TickerProviderStateMixin {
  late final SplashLogoAnimationService _animation = SplashLogoAnimationService(
    vsync: this,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Needs MediaQuery, so it can't run in initState. Only starts once.
    _animation.start(reduceMotion: MediaQuery.disableAnimationsOf(context));
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = SplashLogo.logoSize;
    final wordmarkColor = widget.wordmarkColor ?? AppColors.primaryColor;

    return SizedBox(
      width: size * 2.6,
      height: size * 2.6,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Soft halo behind the logo.
          AnimatedBuilder(
            animation: _animation.haloListenable,
            child: const _Halo(diameter: size * 2.2),
            builder: (context, halo) => Opacity(
              opacity: _animation.haloOpacity,
              child: Transform.scale(scale: _animation.haloScale, child: halo),
            ),
          ),
          // The logo: always exactly logoSize, with one light sweep.
          SizedBox.square(
            dimension: size,
            child: AnimatedBuilder(
              animation: _animation.sheenListenable,
              child: SvgPicture.asset(
                AppVector.appLogo,
                width: size,
                height: size,
              ),
              builder: (context, logo) {
                if (!_animation.isSheenActive) return logo!;
                final gradient = SplashLogoAnimationService.sheenGradient(
                  _animation.sheenProgress,
                );
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: gradient.createShader,
                  child: logo,
                );
              },
            ),
          ),
          // Wordmark below, positioned so the logo stays centred.
          Positioned(
            top: size * 1.3 + size * 0.85,
            child: AnimatedBuilder(
              animation: _animation.wordmarkListenable,
              builder: (context, child) => Opacity(
                opacity: _animation.wordmarkOpacity,
                child: Transform.translate(
                  offset: Offset(0, _animation.wordmarkOffsetY),
                  child: child,
                ),
              ),
              child: Text(
                'Melodix',
                style: TextStyle(
                  color: wordmarkColor,
                  fontSize: 28,
                  fontWeight: FontWeightHelper.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final green = AppColors.primaryColor;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            green.withValues(alpha: 0.38),
            green.withValues(alpha: 0.12),
            green.withValues(alpha: 0),
          ],
          stops: const [0.25, 0.55, 1],
        ),
      ),
    );
  }
}
