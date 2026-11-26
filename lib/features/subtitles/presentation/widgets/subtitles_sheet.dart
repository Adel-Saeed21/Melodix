import 'dart:ui' as ui;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/subtitles/domain/entities/online_subtitle.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_failure.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_track.dart';
import 'package:melodix/features/subtitles/domain/usecases/subtitle_usecases.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitle_search_cubit.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitles_cubit.dart';

/// The subtitles sheet for the open video: off, its tracks, add a file,
/// search online.
Future<void> showSubtitlesSheet(
  BuildContext context, {
  required String videoTitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: context.read<SubtitlesCubit>(),
      child: _SubtitlesSheet(videoTitle: videoTitle),
    ),
  );
}

class _SubtitlesSheet extends StatefulWidget {
  const _SubtitlesSheet({required this.videoTitle});

  final String videoTitle;

  @override
  State<_SubtitlesSheet> createState() => _SubtitlesSheetState();
}

class _SubtitlesSheetState extends State<_SubtitlesSheet> {
  bool _searching = false;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Padding(
        // Room for the keyboard while typing a search.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _searching
              ? _SearchView(
                  videoTitle: widget.videoTitle,
                  onBack: () => setState(() => _searching = false),
                )
              : _TracksView(onSearch: () => setState(() => _searching = true)),
        ),
      ),
    );
  }
}

class _TracksView extends StatelessWidget {
  const _TracksView({required this.onSearch});

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
            _SheetTitle(AppStrings.subtitles),
            RadioGroup<String?>(
              groupValue: selected,
              onChanged: (id) => cubit.select(
                state.tracks.where((t) => t.id == id).firstOrNull,
              ),
              child: Column(
                children: [
                  const RadioListTile<String?>(
                    value: null,
                    title: Text(AppStrings.subtitlesOff),
                  ),
                  for (final track in state.tracks)
                    RadioListTile<String?>(
                      value: track.id,
                      title: Text(
                        track.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_trackDetails(track)),
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
              _Note(AppStrings.subtitlesNone),
            if (state.failure case final failure?)
              _Note(failure.message, error: true),
            const Divider(),
            if (cubit.canImport)
              ListTile(
                leading: state.importing
                    ? SizedBox.square(
                        dimension: 24.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_open_rounded),
                title: const Text(AppStrings.subtitlesAddFromDevice),
                subtitle: const Text(AppStrings.subtitlesAddFromDeviceHint),
                onTap: state.importing ? null : cubit.importFromDevice,
              ),
            if (canSearch)
              ListTile(
                leading: const Icon(Icons.travel_explore_rounded),
                title: const Text(AppStrings.subtitlesSearchOnline),
                subtitle: const Text(AppStrings.subtitlesSearchOnlineHint),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onSearch,
              ),
          ],
        );
      },
    );
  }

  static String _trackDetails(SubtitleTrack track) => [
    switch (track.source) {
      SubtitleSource.nearby => AppStrings.subtitlesFromDevice,
      SubtitleSource.imported => AppStrings.subtitlesImported,
      SubtitleSource.downloaded => AppStrings.subtitlesDownloaded,
    },
    if (track.language case final language?) language.toUpperCase(),
  ].join(' · ');
}

/// Search OpenSubtitles: a name (the video's, to start with), a language,
/// and the results with a download button each.
class _SearchView extends StatefulWidget {
  const _SearchView({required this.videoTitle, required this.onBack});

  final String videoTitle;
  final VoidCallback onBack;

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _query = TextEditingController(
    text: subtitleQueryFor(widget.videoTitle),
  );

  /// The phone's language (when search offers it), else any language.
  late String? _language = _deviceLanguage();

  /// Made by the subtitles cubit (only shown when search is available).
  late final SubtitleSearchCubit _cubit;

  static const List<(String?, String)> languages = subtitleSearchLanguages;

  static String? _deviceLanguage() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode;
    for (final (value, _) in languages) {
      if (value != null && value.split('-').first == code) return value;
    }
    return 'en';
  }

  @override
  void initState() {
    super.initState();
    _cubit = context.read<SubtitlesCubit>().createSearch()!;
    _search();
  }

  void _search() => _cubit.search(_query.text, language: _language);

  @override
  void dispose() {
    _query.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubtitleSearchCubit, SubtitleSearchState>(
      bloc: _cubit,
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Expanded(
                  child: _SheetTitle(
                    AppStrings.subtitlesSearchOnline,
                    padded: false,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: _query,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: AppStrings.subtitlesSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: AppStrings.subtitlesSearch,
                    onPressed: state.status == SubtitleSearchStatus.loading
                        ? null
                        : _search,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
            ),
            verticalSpace(8),
            SizedBox(
              height: 40.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  for (final (code, name) in languages)
                    Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: ChoiceChip(
                        label: Text(name),
                        selected: code == _language,
                        onSelected: (_) {
                          setState(() => _language = code);
                          _search();
                        },
                      ),
                    ),
                ],
              ),
            ),
            verticalSpace(8),
            if (state.downloadFailure case final failure?)
              _Note(_failureText(failure), error: true)
            else if (state.remainingDownloads case final left?)
              _Note(
                [
                  AppStrings.subtitlesDownloadsLeft(left),
                  if (state.resetsIn case final resets?)
                    AppStrings.subtitlesQuotaResets(resets),
                ].join(' '),
              ),
            Flexible(child: _results(state)),
          ],
        );
      },
    );
  }

  Widget _results(SubtitleSearchState state) {
    switch (state.status) {
      case SubtitleSearchStatus.idle:
      case SubtitleSearchStatus.loading:
        return Padding(
          padding: EdgeInsets.all(32.r),
          child: const Center(child: CircularProgressIndicator()),
        );
      case SubtitleSearchStatus.empty:
        return _Note(AppStrings.subtitlesNoResults);
      case SubtitleSearchStatus.failure:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Note(_failureText(state.failure!), error: true),
            if (state.failure is! SubtitleNotConfiguredFailure &&
                state.failure is! SubtitleAuthFailure)
              TextButton(
                onPressed: _search,
                child: const Text(AppStrings.subtitlesTryAgain),
              ),
          ],
        );
      case SubtitleSearchStatus.success:
        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.only(bottom: 16.h),
          itemCount: state.results.length,
          itemBuilder: (context, i) => _ResultTile(
            subtitle: state.results[i],
            downloading: state.downloadingFileId == state.results[i].fileId,
            saved: state.savedFileIds.contains(state.results[i].fileId),
            enabled: state.downloadingFileId == null,
            onDownload: () => _cubit.download(state.results[i]),
          ),
        );
    }
  }

  static String _failureText(SubtitleFailure failure) => switch (failure) {
    SubtitleRateLimitFailure(:final retryAfter?) =>
      '${failure.message} ${AppStrings.subtitlesRetryIn(retryAfter.inSeconds)}',
    SubtitleQuotaFailure(:final resetsIn?) =>
      '${failure.message} ${AppStrings.subtitlesQuotaResets(resetsIn)}',
    _ => failure.message,
  };
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
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
      AppStrings.subtitlesDownloads(subtitle.downloadCount),
      if (subtitle.matchesFile) AppStrings.subtitlesFitsFile,
      if (subtitle.hearingImpaired) AppStrings.subtitlesHearingImpaired,
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
          ? const Tooltip(
              message: AppStrings.subtitlesSaved,
              child: Icon(Icons.check_circle_rounded),
            )
          : IconButton(
              tooltip: AppStrings.subtitlesDownload,
              onPressed: enabled ? onDownload : null,
              icon: const Icon(Icons.download_rounded),
            ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text, {this.padded = true});

  final String text;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padded
          ? EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h)
          : EdgeInsets.zero,
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTextSizes.lg,
          fontWeight: FontWeightHelper.bold,
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text, {this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppTextSizes.sm,
          color: error ? scheme.error : scheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// The languages online subtitle search offers: a code (null: any
/// language) and its name in that language.
const List<(String?, String)> subtitleSearchLanguages = [
  (null, AppStrings.subtitlesAnyLanguage),
  ('en', 'English'),
  ('ar', 'العربية'),
  ('fr', 'Français'),
  ('es', 'Español'),
  ('de', 'Deutsch'),
  ('it', 'Italiano'),
  ('pt-PT', 'Português'),
  ('ru', 'Русский'),
  ('tr', 'Türkçe'),
  ('hi', 'हिन्दी'),
  ('ja', '日本語'),
  ('ko', '한국어'),
  ('zh-CN', '中文'),
];
