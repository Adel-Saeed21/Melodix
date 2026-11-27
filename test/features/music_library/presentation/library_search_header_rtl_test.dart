import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_field.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_header.dart';

/// The Music header in both reading directions: collapsed, the round
/// button shows the 🔍 (it once showed the ✕ in Arabic), and the title
/// sits on the reading side.
void main() {
  Future<void> pump(WidgetTester tester, TextDirection direction) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LibrarySearchHeader(
                  expand: const AlwaysStoppedAnimation(0),
                  titleOut: const AlwaysStoppedAnimation(0),
                  isOpen: false,
                  songCount: 12,
                  onOpen: () {},
                  field: LibrarySearchField(
                    controller: TextEditingController(),
                    onChanged: (_) {},
                    onClose: () {},
                    autofocus: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The collapsed pill: the clipped box the field shows through.
  Rect pill(WidgetTester tester) =>
      tester.getRect(find.byType(ClipRRect).first);

  bool showsIn(WidgetTester tester, IconData icon, Rect area) {
    final finder = find.byIcon(icon);
    if (finder.evaluate().isEmpty) return false;
    return area.contains(tester.getCenter(finder.first));
  }

  for (final (name, direction) in [
    ('English (left to right)', TextDirection.ltr),
    ('Arabic (right to left)', TextDirection.rtl),
  ]) {
    testWidgets('$name: the collapsed button shows 🔍, not ✕', (tester) async {
      await pump(tester, direction);
      final button = pill(tester);
      expect(button.width, lessThan(80), reason: 'collapsed');
      expect(showsIn(tester, Icons.search_rounded, button), isTrue);
      expect(showsIn(tester, Icons.close_rounded, button), isFalse);
    });
  }

  testWidgets('the title and the button swap sides in Arabic', (tester) async {
    await pump(tester, TextDirection.ltr);
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(pill(tester).center.dx, greaterThan(width / 2), reason: 'en');
    expect(tester.getCenter(find.text('Music')).dx, lessThan(width / 2));

    await pump(tester, TextDirection.rtl);
    expect(pill(tester).center.dx, lessThan(width / 2), reason: 'ar');
    expect(tester.getCenter(find.text('Music')).dx, greaterThan(width / 2));
  });
}
