import 'package:material_ui/material_ui.dart';

import 'package:melodix/core/config/assets/app_assets.dart';

class GetStartLogo extends StatelessWidget {
  const GetStartLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(Assets.assetsImagesAppLogo);
  }
}
