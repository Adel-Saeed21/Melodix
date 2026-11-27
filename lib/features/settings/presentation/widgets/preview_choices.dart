import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/settings/presentation/widgets/preview_choices/preview_card.dart';

/// One option in a [PreviewChoices] row.
class PreviewOption<T> {
  const PreviewOption(this.value, this.label, this.preview);

  final T value;
  final String label;

  /// Draws the option (it's given whether it's chosen).
  final Widget Function(bool selected) preview;
}

/// A row of cards, each a small drawing of what the option looks like and
/// its name; the chosen one lifts, glows and gets the accent ring.
class PreviewChoices<T> extends StatelessWidget {
  const PreviewChoices({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.previewHeight = 64,
  });

  final List<PreviewOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double previewHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) horizontalSpace(10),
          Expanded(
            child: PreviewCard(
              label: options[i].label,
              selected: options[i].value == value,
              previewHeight: previewHeight.r,
              onTap: () => onChanged(options[i].value),
              preview: options[i].preview(options[i].value == value),
            ),
          ),
        ],
      ],
    );
  }
}

/// A tiny screen (a few list rows) with the music bar drawn in [style].
class MusicBarPreview extends StatelessWidget {
  const MusicBarPreview(this.style, {super.key});

  final MiniPlayerStyle style;

  @override
  Widget build(BuildContext context) => _paint(
    context,
    (accent, ink, card) => _MusicBarPainter(style, accent, ink, card),
  );
}

/// A tiny list with some rows ticked and the actions bar in [style].
class SelectionBarPreview extends StatelessWidget {
  const SelectionBarPreview(this.style, {super.key});

  final SelectionBarStyle style;

  @override
  Widget build(BuildContext context) => _paint(
    context,
    (accent, ink, card) => _SelectionBarPainter(style, accent, ink, card),
  );
}

Widget _paint(
  BuildContext context,
  CustomPainter Function(Color accent, Color ink, Color card) painter,
) {
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  return CustomPaint(
    painter: painter(
      theme.primaryColor,
      theme.colorScheme.onSurface,
      dark ? const Color(0xff2A2A2A) : Colors.white,
    ),
    child: const SizedBox.expand(),
  );
}

/// A big icon in the accent's tint, for choices that are places rather
/// than looks (the tab to open on).
class IconPreview extends StatelessWidget {
  const IconPreview(this.icon, {super.key, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  accent.withValues(alpha: 0.28),
                  accent.withValues(alpha: 0.06),
                ],
              )
            : null,
      ),
      child: Center(
        child: Icon(
          icon,
          size: 26.r,
          color: selected
              ? accent
              : theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

/// Rounded "text" lines for the list behind the bars.
void _rows(Canvas canvas, Size size, Color ink, {required int count}) {
  final rowH = size.height / 6;
  for (var i = 0; i < count; i++) {
    final y = 8 + i * (rowH + 4);
    final cover = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, y, rowH, rowH),
      const Radius.circular(3),
    );
    canvas.drawRRect(cover, Paint()..color = ink.withValues(alpha: 0.14));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          12 + rowH,
          y + rowH * 0.3,
          size.width * (0.45 - i * 0.06),
          rowH * 0.4,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = ink.withValues(alpha: 0.18),
    );
  }
}

class _MusicBarPainter extends CustomPainter {
  _MusicBarPainter(this.style, this.accent, this.ink, this.card);

  final MiniPlayerStyle style;
  final Color accent;
  final Color ink;
  final Color card;

  @override
  void paint(Canvas canvas, Size size) {
    _rows(canvas, size, ink, count: 3);
    final w = size.width;
    final h = size.height;
    final fill = Paint()..color = card;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final accentPaint = Paint()..color = accent;
    switch (style) {
      case MiniPlayerStyle.classic:
        // A card with a cover, a title, play and a seek line.
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(5, h - 22, w - 10, 18),
          const Radius.circular(5),
        );
        canvas
          ..drawRRect(r.shift(const Offset(0, 1)), shadow)
          ..drawRRect(r, fill)
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(8, h - 19, 10, 10),
              const Radius.circular(2),
            ),
            accentPaint,
          )
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(21, h - 16, w * 0.35, 4),
              const Radius.circular(2),
            ),
            Paint()..color = ink.withValues(alpha: 0.5),
          )
          ..drawCircle(Offset(w - 14, h - 14), 4.5, accentPaint)
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(8, h - 7, w - 16, 1.6),
              const Radius.circular(1),
            ),
            Paint()..color = ink.withValues(alpha: 0.15),
          )
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(8, h - 7, (w - 16) * 0.4, 1.6),
              const Radius.circular(1),
            ),
            accentPaint,
          );
      case MiniPlayerStyle.capsule:
        // A floating pill: a round cover with a progress ring, play.
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.18, h - 22, w * 0.64, 16),
          const Radius.circular(8),
        );
        canvas
          ..drawRRect(r.shift(const Offset(0, 1)), shadow)
          ..drawRRect(r, fill);
        final c = Offset(w * 0.18 + 8, h - 14);
        canvas
          ..drawCircle(c, 5, Paint()..color = ink.withValues(alpha: 0.2))
          ..drawArc(
            Rect.fromCircle(center: c, radius: 6),
            -1.57,
            3.8,
            false,
            Paint()
              ..color = accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..strokeCap = StrokeCap.round,
          )
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.18 + 17, h - 16, w * 0.22, 4),
              const Radius.circular(2),
            ),
            Paint()..color = ink.withValues(alpha: 0.5),
          )
          ..drawCircle(Offset(w * 0.82 - 8, h - 14), 4.5, accentPaint);
      case MiniPlayerStyle.minimal:
        // A flat bar edge to edge, a thin progress line along its top.
        canvas
          ..drawRect(Rect.fromLTWH(0, h - 18, w, 18), fill)
          ..drawRect(
            Rect.fromLTWH(0, h - 18, w, 1.6),
            Paint()..color = ink.withValues(alpha: 0.12),
          )
          ..drawRect(Rect.fromLTWH(0, h - 18, w * 0.55, 1.6), accentPaint)
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(8, h - 11, w * 0.4, 4),
              const Radius.circular(2),
            ),
            Paint()..color = ink.withValues(alpha: 0.5),
          )
          ..drawCircle(Offset(w - 12, h - 9), 3.5, accentPaint);
    }
  }

  @override
  bool shouldRepaint(_MusicBarPainter old) =>
      old.style != style ||
      old.accent != accent ||
      old.ink != ink ||
      old.card != card;
}

class _SelectionBarPainter extends CustomPainter {
  _SelectionBarPainter(this.style, this.accent, this.ink, this.card);

  final SelectionBarStyle style;
  final Color accent;
  final Color ink;
  final Color card;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final side = style == SelectionBarStyle.side;
    final listWidth = side ? w - 22 : w;
    // Rows, the first two ticked.
    final rowH = h / 6;
    for (var i = 0; i < 4; i++) {
      final y = 8 + i * (rowH + 4);
      final ticked = i < 2;
      final c = Offset(12, y + rowH / 2);
      canvas
        ..drawCircle(
          c,
          rowH * 0.42,
          Paint()
            ..color = ticked ? accent : ink.withValues(alpha: 0.25)
            ..style = ticked ? PaintingStyle.fill : PaintingStyle.stroke
            ..strokeWidth = 1,
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(20, y + rowH * 0.3, listWidth * 0.5, rowH * 0.4),
            const Radius.circular(3),
          ),
          Paint()
            ..color = ticked
                ? accent.withValues(alpha: 0.45)
                : ink.withValues(alpha: 0.18),
        );
    }
    final bar = side
        ? RRect.fromRectAndRadius(
            Rect.fromLTWH(w - 16, 8, 11, h - 16),
            const Radius.circular(6),
          )
        : RRect.fromRectAndRadius(
            Rect.fromLTWH(6, h - 16, w - 12, 11),
            const Radius.circular(6),
          );
    canvas
      ..drawRRect(
        bar.shift(const Offset(0, 1)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawRRect(bar, Paint()..color = card);
    // Three action dots along the bar.
    for (var i = 0; i < 3; i++) {
      final t = (i + 1) / 4;
      final c = side
          ? Offset(bar.center.dx, bar.top + bar.height * t)
          : Offset(bar.left + bar.width * t, bar.center.dy);
      canvas.drawCircle(
        c,
        2.4,
        Paint()..color = i == 0 ? accent : ink.withValues(alpha: 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(_SelectionBarPainter old) =>
      old.style != style ||
      old.accent != accent ||
      old.ink != ink ||
      old.card != card;
}
