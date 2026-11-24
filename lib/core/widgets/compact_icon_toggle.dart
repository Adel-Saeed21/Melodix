import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';

/// One choice of a [CompactIconToggle].
class IconToggleOption<T> {
  const IconToggleOption(this.value, this.icon, this.label);

  final T value;
  final IconData icon;

  /// For the tooltip and screen readers.
  final String label;
}

/// A small pill of icons, one per choice, the chosen one highlighted: a
/// compact choice for the end of a settings row (theme, positions…).
class CompactIconToggle<T> extends StatelessWidget {
  const CompactIconToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<IconToggleOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.r),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              _Choice(
                option: option,
                selected: option.value == value,
                onTap: () => onChanged(option.value),
              ),
          ],
        ),
      ),
    );
  }
}

class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final IconToggleOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final radius = BorderRadius.circular(9.r);
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      excludeSemantics: true,
      child: Tooltip(
        message: option.label,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 38.r,
            height: 32.r,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: selected
                  ? theme.colorScheme.surfaceContainerHighest
                  : Colors.transparent,
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: Icon(
              option.icon,
              size: 18.r,
              color: selected ? onSurface : onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
