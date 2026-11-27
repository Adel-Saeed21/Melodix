import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/preferences/library_filter.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';
import 'package:melodix/core/widgets/settings/settings_subpage.dart';

/// Music filters: the shortest song the library shows, and each music
/// folder on or off. Nothing is deleted (see [LibraryFilter]).
class LibraryFiltersPage extends StatelessWidget {
  const LibraryFiltersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final filters = context.watch<LibraryFilterCubit>();
    final filter = filters.state;
    final songs = context.select<MusicLibraryBloc, List<Song>>(
      (bloc) => bloc.state.songs,
    );
    // Folders with songs showing, and the ones turned off (their songs
    // aren't in the library now, so no count).
    final counts = <String, int>{};
    for (final song in songs) {
      final folder = LibraryFilter.folderOf(song.path);
      counts[folder] = (counts[folder] ?? 0) + 1;
    }
    final folders = {...counts.keys, ...filter.excludedFolders}.toList()
      ..sort(
        (a, b) => _name(a).toLowerCase().compareTo(_name(b).toLowerCase()),
      );
    final accent = Theme.of(context).primaryColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SettingsSubpage(
      title: context.l10n.libraryFilters,
      children: [
        SettingsSection(
          icon: Icons.timer_rounded,
          title: context.l10n.minimumLength,
          children: [
            SettingRow(
              title: context.l10n.minimumLength,
              subtitle: context.l10n.minimumLengthHint,
              below: Wrap(
                spacing: 8.r,
                runSpacing: 8.r,
                children: [
                  for (final seconds in LibraryFilter.minSecondsChoices)
                    ChoiceChip(
                      label: Text(context.l10n.minimumLengthValue(seconds)),
                      selected: filter.minSeconds == seconds,
                      onSelected: (_) => filters.setMinSeconds(seconds),
                    ),
                ],
              ),
            ),
          ],
        ),
        SettingsSection(
          icon: Icons.folder_rounded,
          title: context.l10n.folders,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16.w, 14.h, 16.w, 6.h),
              child: Text(
                context.l10n.foldersHint,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.6),
                  fontSize: AppTextSizes.sm,
                ),
              ),
            ),
            if (folders.isEmpty)
              SettingRow(title: context.l10n.noFolders)
            else
              for (final folder in folders)
                SwitchListTile(
                  secondary: Icon(
                    filter.excludedFolders.contains(folder)
                        ? Icons.folder_off_rounded
                        : Icons.folder_rounded,
                    color: filter.excludedFolders.contains(folder)
                        ? onSurface.withValues(alpha: 0.4)
                        : accent,
                  ),
                  title: Text(
                    _name(folder),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      if (counts[folder] case final count?)
                        context.l10n.folderSongs(count),
                      folder,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: !filter.excludedFolders.contains(folder),
                  onChanged: (on) => filters.setFolder(folder, included: on),
                ),
          ],
        ),
      ],
    );
  }

  static String _name(String folder) {
    final slash = folder.lastIndexOf('/');
    return slash < 0 || slash == folder.length - 1
        ? folder
        : folder.substring(slash + 1);
  }
}
