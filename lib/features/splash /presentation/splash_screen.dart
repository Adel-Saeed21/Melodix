import 'package:material_ui/material_ui.dart';

import 'package:go_router/go_router.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/service/onboarding_service.dart';

import 'package:melodix/features/splash /presentation/widgets/splash_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateFromSplash();
  }

  Future<void> _navigateFromSplash() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    context.go(
      OnboardingService.isCompleted ? Routes.homeScreen : Routes.getStartScreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The native splash follows the system light/dark mode (it can't know
    // the in-app theme), so match it here for a seamless hand-off.
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.splashDarkBackground
          : AppColors.splashLightBackground,
      body: const Center(child: SplashLogo()),
    );
  }
}
