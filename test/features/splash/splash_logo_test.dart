import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/splash /presentation/widgets/splash_logo.dart';

void main() {
  Future<void> pumpLogo(WidgetTester tester, {bool reduceMotion = false}) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: const MaterialApp(
          home: Scaffold(body: Center(child: SplashLogo())),
        ),
      ),
    );
  }

  Opacity wordmarkOpacity(WidgetTester tester) => tester.widget<Opacity>(
    find
        .ancestor(of: find.text('Melodix'), matching: find.byType(Opacity))
        .first,
  );

  testWidgets('logo is 120x120 and centred on the first frame', (tester) async {
    await pumpLogo(tester);

    final logo = find.byType(SvgPicture);
    expect(tester.getSize(logo), const Size(120, 120));
    final screenCenter = tester.getCenter(find.byType(Scaffold));
    expect(tester.getCenter(logo), screenCenter);
    // Wordmark starts invisible so frame one matches the native splash.
    expect(wordmarkOpacity(tester).opacity, 0);
  });

  testWidgets('logo size never changes while effects animate', (tester) async {
    await pumpLogo(tester);

    for (var ms = 0; ms <= 3000; ms += 250) {
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        tester.getSize(find.byType(SvgPicture).first),
        const Size(120, 120),
      );
    }
    expect(wordmarkOpacity(tester).opacity, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion shows the final state immediately', (
    tester,
  ) async {
    await pumpLogo(tester, reduceMotion: true);
    await tester.pump();

    expect(wordmarkOpacity(tester).opacity, 1);
    expect(tester.getSize(find.byType(SvgPicture)), const Size(120, 120));
  });
}
