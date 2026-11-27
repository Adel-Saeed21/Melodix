import 'dart:ui' as ui;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/subtitles/domain/entities/subtitle_failure.dart';
import 'package:melodix/features/subtitles/domain/usecases/subtitle_usecases.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitle_search_cubit.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitles_cubit.dart';
import 'package:melodix/features/subtitles/presentation/widgets/subtitles_sheet.dart';
import 'package:melodix/features/subtitles/presentation/widgets/subtitles_sheet/subtitle_result_tile.dart';
import 'package:melodix/features/subtitles/presentation/widgets/subtitles_sheet/subtitle_sheet_title.dart';
import 'package:melodix/features/subtitles/presentation/widgets/subtitles_sheet/subtitle_note.dart';

/// Search OpenSubtitles: a name (the video's, to start with), a language,
/// and the results with a download button each.
class SubtitleSearchView extends StatefulWidget {
  const SubtitleSearchView({
    super.key,
    required this.videoTitle,
    required this.onBack,
  });

  final String videoTitle;
  final VoidCallback onBack;

  @override
  State<SubtitleSearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SubtitleSearchView> {
  late final TextEditingController _query = TextEditingController(
    text: subtitleQueryFor(widget.videoTitle),
  );

  /// The phone's language (when search offers it), else any language.
  late String? _language = _deviceLanguage();

  /// Made by the subtitles cubit (only shown when search is available).
  late final SubtitleSearchCubit _cubit;

  static const List<(String?, String?)> languages = subtitleSearchLanguages;

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
                Expanded(
                  child: SubtitleSheetTitle(
                    context.l10n.subtitlesSearchOnline,
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
                  hintText: context.l10n.subtitlesSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: context.l10n.subtitlesSearch,
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
                      padding: EdgeInsetsDirectional.only(end: 8.w),
                      child: ChoiceChip(
                        label: Text(name ?? context.l10n.subtitlesAnyLanguage),
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
              SubtitleNote(_failureText(failure, context.l10n), error: true)
            else if (state.remainingDownloads case final left?)
              SubtitleNote(
                [
                  context.l10n.subtitlesDownloadsLeft(left),
                  if (state.resetsIn case final resets?)
                    context.l10n.subtitlesQuotaResets(resets),
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
        return SubtitleNote(context.l10n.subtitlesNoResults);
      case SubtitleSearchStatus.failure:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SubtitleNote(
              _failureText(state.failure!, context.l10n),
              error: true,
            ),
            if (state.failure is! SubtitleNotConfiguredFailure &&
                state.failure is! SubtitleAuthFailure)
              TextButton(
                onPressed: _search,
                child: Text(context.l10n.subtitlesTryAgain),
              ),
          ],
        );
      case SubtitleSearchStatus.success:
        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.only(bottom: 16.h),
          itemCount: state.results.length,
          itemBuilder: (context, i) => SubtitleResultTile(
            subtitle: state.results[i],
            downloading: state.downloadingFileId == state.results[i].fileId,
            saved: state.savedFileIds.contains(state.results[i].fileId),
            enabled: state.downloadingFileId == null,
            onDownload: () => _cubit.download(state.results[i]),
          ),
        );
    }
  }

  static String _failureText(SubtitleFailure failure, AppLocalizations l10n) =>
      switch (failure) {
        SubtitleRateLimitFailure(:final retryAfter?) =>
          '${failure.message} ${l10n.subtitlesRetryIn(retryAfter.inSeconds)}',
        SubtitleQuotaFailure(:final resetsIn?) =>
          '${failure.message} ${l10n.subtitlesQuotaResets(resetsIn)}',
        _ => failure.message,
      };
}
