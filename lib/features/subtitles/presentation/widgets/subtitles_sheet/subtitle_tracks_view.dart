import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_track.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitles_cubit.dart';
import 'package:melodix/features/subtitles/presentation/widgets/subtitles_sheet/subtitle_sheet_title.dart';
import 'package:melodix/features/subtitles/presentation/widgets/subtitles_sheet/subtitle_note.dart';

class SubtitleTracksView extends StatelessWidget {
  const SubtitleTracksView({super.key, required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubtitlesCubit>();
    final canSearch = cubit.canSearchOnline;
    return BlocBuilder<SubtitlesCubit, SubtitlesState>(
      builder: (context, state) {
        final selected = state.selectedId;
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(bottom: 16.h),
          children: [
            SubtitleSheetTitle(context.l10n.subtitles),
            RadioGroup<String?>(
              groupValue: selected,
              onChanged: (id) => cubit.select(
                state.tracks.where((t) => t.id == id).firstOrNull,
              ),
              child: Column(
                children: [
                  RadioListTile<String?>(
                    value: null,
                    title: Text(context.l10n.subtitlesOff),
                  ),
                  for (final track in state.tracks)
                    RadioListTile<String?>(
                      value: track.id,
                      title: Text(
                        track.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_trackDetails(track, context.l10n)),
                      secondary:
                          state.status == SubtitlesStatus.loading &&
                              track.id == selected
                          ? SizedBox.square(
                              dimension: 20.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : null,
                    ),
                ],
              ),
            ),
            if (state.tracks.isEmpty && state.status != SubtitlesStatus.loading)
              SubtitleNote(context.l10n.subtitlesNone),
            if (state.failure case final failure?)
              SubtitleNote(failure.message, error: true),
            const Divider(),
            if (cubit.canImport)
              ListTile(
                leading: state.importing
                    ? SizedBox.square(
                        dimension: 24.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_open_rounded),
                title: Text(context.l10n.subtitlesAddFromDevice),
                subtitle: Text(context.l10n.subtitlesAddFromDeviceHint),
                onTap: state.importing ? null : cubit.importFromDevice,
              ),
            if (canSearch)
              ListTile(
                leading: const Icon(Icons.travel_explore_rounded),
                title: Text(context.l10n.subtitlesSearchOnline),
                subtitle: Text(context.l10n.subtitlesSearchOnlineHint),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onSearch,
              ),
          ],
        );
      },
    );
  }

  static String _trackDetails(SubtitleTrack track, AppLocalizations l10n) => [
    switch (track.source) {
      SubtitleSource.nearby => l10n.subtitlesFromDevice,
      SubtitleSource.imported => l10n.subtitlesImported,
      SubtitleSource.downloaded => l10n.subtitlesDownloaded,
    },
    if (track.language case final language?) language.toUpperCase(),
  ].join(' · ');
}
