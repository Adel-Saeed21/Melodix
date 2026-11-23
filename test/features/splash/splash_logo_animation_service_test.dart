import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/splash /presentation/services/splash_logo_animation_service.dart';

void main() {
  testWidgets('starts hidden: no halo, no sheen, no wordmark', (tester) async {
    final service = SplashLogoAnimationService(vsync: const TestVSync());
    addTearDown(service.dispose);

    expect(service.haloOpacity, 0);
    expect(service.haloScale, 0.9);
    expect(service.isSheenActive, isFalse);
    expect(service.wordmarkOpacity, 0);
    expect(service.wordmarkOffsetY, 10);
  });

  testWidgets('reduced motion jumps to the final state', (tester) async {
    final service = SplashLogoAnimationService(vsync: const TestVSync());
    addTearDown(service.dispose);

    service.start(reduceMotion: true);

    expect(service.wordmarkOpacity, 1);
    expect(service.wordmarkOffsetY, 0);
    expect(service.sheenProgress, 1);
    expect(service.isSheenActive, isFalse);
    expect(service.haloOpacity, greaterThan(0.75));
  });

  testWidgets('plays the intro, then keeps the halo breathing', (tester) async {
    late SplashLogoAnimationService service;
    await tester.pumpWidget(
      _Host(
        onCreate: (vsync) => service = SplashLogoAnimationService(vsync: vsync),
      ),
    );
    service.start(reduceMotion: false);
    await tester.pump(); // first frame records the start time

    // Mid-intro the sheen is crossing the logo.
    await tester.pump(const Duration(milliseconds: 750));
    expect(service.isSheenActive, isTrue);
    expect(service.wordmarkOpacity, inExclusiveRange(0, 1));

    // After the intro everything is in place.
    await tester.pump(const Duration(milliseconds: 800));
    expect(service.wordmarkOpacity, 1);
    expect(service.isSheenActive, isFalse);

    // The halo keeps pulsing.
    final before = service.haloScale;
    await tester.pump(const Duration(milliseconds: 1200));
    expect(service.haloScale, isNot(before));

    // Like the widget: stop the endless breathing before the tree goes away.
    service.dispose();
  });

  testWidgets('start only runs once and dispose is safe twice', (tester) async {
    final service = SplashLogoAnimationService(vsync: const TestVSync());
    service.start(reduceMotion: true);
    service.start(reduceMotion: false); // ignored
    expect(service.wordmarkOpacity, 1);

    service.dispose();
    service.dispose();
  });

  test('sheen gradient travels from left to right', () {
    final early = SplashLogoAnimationService.sheenGradient(0.2).stops![1];
    final late = SplashLogoAnimationService.sheenGradient(0.8).stops![1];
    expect(late, greaterThan(early));
  });
}

/// Provides a real ticker so the service animates with [WidgetTester.pump].
class _Host extends StatefulWidget {
  const _Host({required this.onCreate});

  final void Function(TickerProvider vsync) onCreate;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    widget.onCreate(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
