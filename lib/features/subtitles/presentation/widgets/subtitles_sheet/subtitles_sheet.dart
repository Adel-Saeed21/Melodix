import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/subtitles/presentation/widgets/subtitles_sheet/subtitle_tracks_view.dart';
import 'package:melodix/features/subtitles/presentation/widgets/subtitles_sheet/subtitle_search_view.dart';

class SubtitlesSheet extends StatefulWidget {
  const SubtitlesSheet({super.key, required this.videoTitle});

  final String videoTitle;

  @override
  State<SubtitlesSheet> createState() => _SubtitlesSheetState();
}

class _SubtitlesSheetState extends State<SubtitlesSheet> {
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
              ? SubtitleSearchView(
                  videoTitle: widget.videoTitle,
                  onBack: () => setState(() => _searching = false),
                )
              : SubtitleTracksView(
                  onSearch: () => setState(() => _searching = true),
                ),
        ),
      ),
    );
  }
}
