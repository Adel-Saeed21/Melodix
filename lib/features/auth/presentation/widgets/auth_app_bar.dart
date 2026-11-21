import 'package:material_ui/material_ui.dart';

import 'package:go_router/go_router.dart';
import 'package:melodix/core/config/assets/app_assets.dart';
import 'package:melodix/features/auth/presentation/widgets/back_circle_button.dart';

class AuthAppBar extends StatelessWidget {
  const AuthAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: BackCircleButton(
            onTap: () {
              if (context.canPop()) context.pop();
            },
          ),
        ),
        Image.asset(
          Assets.assetsImagesAppLogo,
          width: width * 0.3,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
