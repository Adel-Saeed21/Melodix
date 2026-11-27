import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitles_cubit.dart';
import 'package:melodix/features/subtitles/presentation/widgets/subtitles_sheet/subtitles_sheet.dart';

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
      child: SubtitlesSheet(videoTitle: videoTitle),
    ),
  );
}

/// The languages online subtitle search offers: a code and its name in
/// that language (both null: any language, named in the app's language).
const List<(String?, String?)> subtitleSearchLanguages = [
  (null, null),
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
