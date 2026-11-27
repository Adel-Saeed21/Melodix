import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/preferences/app_language.dart';

/// Changes the app's language without a jolt: the screen fades into its
/// background, the language (and with Arabic, the reading direction)
/// changes underneath, then it fades back in. Pages, scroll positions and
/// what's playing are all kept: nothing is rebuilt from scratch.
///
/// Sits over every page (in `MaterialApp.builder`); [change] finds it.
class LanguageSwitcher extends StatefulWidget {
  const LanguageSwitcher({super.key, required this.child});

  final Widget child;

  /// The fading layer (tests look at its opacity).
  @visibleForTesting
  static const Key veilKey = ValueKey('language-switch-veil');

  static const Duration fadeOut = Duration(milliseconds: 180);
  static const Duration fadeIn = Duration(milliseconds: 320);

  /// Switches to [language] (saved in [AppLanguageCubit]).
  static Future<void> change(BuildContext context, AppLanguage language) {
    final cubit = context.read<AppLanguageCubit>();
    final localization = EasyLocalization.of(context);
    Future<void> apply() async {
      cubit.choose(language);
      await localization?.setLocale(cubit.resolvedLocale);
    }

    final switcher = context.findAncestorStateOfType<_LanguageSwitcherState>();
    return switcher == null ? apply() : switcher._switch(apply);
  }

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _veil = AnimationController(vsync: this);
  bool _switching = false;

  Future<void> _switch(Future<void> Function() apply) async {
    if (_switching) return;
    setState(() => _switching = true);
    try {
      await _veil.animateTo(
        1,
        duration: LanguageSwitcher.fadeOut,
        curve: Curves.easeIn,
      );
      await apply();
      // Let the new language lay out under the veil before lifting it.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      await _veil.animateBack(
        0,
        duration: LanguageSwitcher.fadeIn,
        curve: Curves.easeOut,
      );
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  void dispose() {
    _veil.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // No taps half-way through a switch.
        AbsorbPointer(absorbing: _switching, child: widget.child),
        Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              key: LanguageSwitcher.veilKey,
              opacity: _veil,
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
