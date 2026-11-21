import 'package:material_ui/material_ui.dart';

import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:melodix/core/config/assets/app_vector.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/service/secure_storage_service.dart';

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
    final hasToken = await SecureStorageService.hasValidToken();

    if (!mounted) return;
    context.go(hasToken ? Routes.homeScreen : Routes.getStartScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SvgPicture.asset(AppVector.appLogo, width: 120, height: 120),
      ),
    );
  }
}
