import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';

/// The app's size scaling (`.w`, `.h`, `.r`, `.sp`), designed for a phone
/// held either way.
///
/// * The design is portrait (375 × 812). Scaled against that while the
///   phone is sideways, every `.w` came out over twice as wide and heights
///   assumed a 700-tall screen, so pages overflowed. Sideways, it scales
///   against the same design turned (812 × 375): sizes stay as designed.
/// * Sizes are worked out when a widget builds, and turning the phone only
///   rebuilds widgets that depend on the screen's size: the rest kept their
///   old sizes in the new layout. So when the screen's size changes (a turn,
///   not the keyboard), every widget below is rebuilt once, with its state
///   kept.
class AppScreenUtilInit extends StatefulWidget {
  const AppScreenUtilInit({super.key, required this.child});

  final Widget child;

  static const Size portraitDesign = Size(375, 812);
  static const Size landscapeDesign = Size(812, 375);

  @override
  State<AppScreenUtilInit> createState() => _AppScreenUtilInitState();
}

class _AppScreenUtilInitState extends State<AppScreenUtilInit>
    with WidgetsBindingObserver {
  Size? _screen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final screen = View.of(context).physicalSize;
    if (screen == _screen) return; // e.g. the keyboard: sizes unchanged
    _screen = screen;
    // Before the next frame (not during one): it then builds top-down, so
    // the new scaling is set before anything below reads it.
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    context.visitChildElements(rebuild);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screen = View.of(context).physicalSize;
    _screen ??= screen;
    final landscape = screen.width > screen.height;
    return ScreenUtilPlusInit(
      designSize: landscape
          ? AppScreenUtilInit.landscapeDesign
          : AppScreenUtilInit.portraitDesign,
      minTextAdapt: true,
      // Split-screen mode assumes at least 700 dp of height: right for a
      // portrait window, wrong for a phone on its side.
      splitScreenMode: !landscape,
      child: widget.child,
    );
  }
}
