import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/l10n/language_switcher.dart';
import 'package:melodix/core/preferences/app_language.dart';
import 'package:melodix/core/service/spacing.dart';

/// The app's language: the phone's, English or Arabic, one row each, the
/// chosen one ticked.
///
/// Each language is named in itself ("العربية"), so it can be found
/// whatever the app is showing, with its name in the app's language
/// below. The phone's row says which language that is now.
class LanguageSetting extends StatelessWidget {
  const LanguageSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AppLanguageCubit>();
    final l10n = context.l10n;
    final current = AppLanguage.values
        .where(
          (l) => l.locale?.languageCode == cubit.resolvedLocale.languageCode,
        )
        .firstOrNull;
    final divider = Divider(
      height: 1,
      indent: 66.w,
      endIndent: 16.w,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
    );
    return Column(
      children: [
        for (final language in AppLanguage.values) ...[
          if (language != AppLanguage.values.first) divider,
          _LanguageTile(
            badge: switch (language) {
              AppLanguage.system => const Icon(Icons.smartphone_rounded),
              AppLanguage.english => const Text('En'),
              AppLanguage.arabic => const Text('ع'),
            },
            title: language.nativeName ?? l10n.languageSystem,
            subtitle: switch (language) {
              AppLanguage.system => l10n.languageSystemNow(
                current?.nativeName ?? 'English',
              ),
              AppLanguage.english => l10n.languageEnglish,
              AppLanguage.arabic => l10n.languageArabic,
            },
            selected: cubit.state == language,
            onTap: () => LanguageSwitcher.change(context, language),
          ),
        ],
      ],
    );
  }
}

/// One language: its badge, name (and a second line), and a tick when
/// it's the one in use.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final Widget badge;
  final String title;

  /// Left out when it would only repeat [title] (Arabic, in Arabic).
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  static const Duration _animation = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final onSurface = theme.colorScheme.onSurface;
    final onAccent = theme.colorScheme.onPrimary;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: selected ? null : onTap,
        child: AnimatedContainer(
          duration: _animation,
          curve: Curves.easeOutCubic,
          color: selected ? accent.withValues(alpha: 0.08) : Colors.transparent,
          padding: EdgeInsetsDirectional.fromSTEB(16.w, 12.h, 16.w, 12.h),
          child: Row(
            children: [
              AnimatedContainer(
                duration: _animation,
                curve: Curves.easeOutCubic,
                width: 36.r,
                height: 36.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? accent : accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: IconTheme.merge(
                  data: IconThemeData(
                    size: 19.r,
                    color: selected ? onAccent : accent,
                  ),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color: selected ? onAccent : accent,
                      fontSize: AppTextSizes.base,
                      fontWeight: FontWeightHelper.bold,
                      height: 1,
                    ),
                    child: ExcludeSemantics(child: badge),
                  ),
                ),
              ),
              horizontalSpace(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: AppTextSizes.base,
                        fontWeight: selected
                            ? FontWeightHelper.bold
                            : FontWeightHelper.semiBold,
                      ),
                    ),
                    if (subtitle != title) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.6),
                          fontSize: AppTextSizes.sm,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              horizontalSpace(8),
              AnimatedSwitcher(
                duration: _animation,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: selected
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('selected'),
                        color: accent,
                        size: 24.r,
                      )
                    : Icon(
                        Icons.radio_button_unchecked_rounded,
                        key: const ValueKey('unselected'),
                        color: onSurface.withValues(alpha: 0.25),
                        size: 24.r,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
