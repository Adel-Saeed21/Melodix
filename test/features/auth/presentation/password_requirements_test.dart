import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/features/auth/presentation/widgets/password_requirements.dart';

void main() {
  testWidgets('checks off requirements as the password changes', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(375, 812),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(body: PasswordRequirements(controller: controller)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('At least 8 characters'), findsOneWidget);
    expect(find.text('A symbol (!@#...)'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

    controller.text = 'abc1';
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    controller.text = 'Abcdef1!';
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
  });
}
