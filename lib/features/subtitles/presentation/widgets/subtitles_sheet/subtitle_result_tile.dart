import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/subtitles/domain/entities/online_subtitle.dart';

class SubtitleResultTile extends StatelessWidget {
  const SubtitleResultTile({
    super.key,
    required this.subtitle,
    required this.downloading,
    required this.saved,
    required this.enabled,
    required this.onDownload,
  });

  final OnlineSubtitle subtitle;
  final bool downloading;
  final bool saved;
  final bool enabled;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (subtitle.language.isNotEmpty) subtitle.language.toUpperCase(),
      subtitle.format.toUpperCase(),
      context.l10n.subtitlesDownloads(subtitle.downloadCount),
      if (subtitle.matchesFile) context.l10n.subtitlesFitsFile,
      if (subtitle.hearingImpaired) context.l10n.subtitlesHearingImpaired,
    ].join(' · ');
    return ListTile(
      title: Text(subtitle.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(details),
      trailing: downloading
          ? SizedBox.square(
              dimension: 24.r,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : saved
          ? Tooltip(
              message: context.l10n.subtitlesSaved,
              child: Icon(Icons.check_circle_rounded),
            )
          : IconButton(
              tooltip: context.l10n.subtitlesDownload,
              onPressed: enabled ? onDownload : null,
              icon: const Icon(Icons.download_rounded),
            ),
    );
  }
}
