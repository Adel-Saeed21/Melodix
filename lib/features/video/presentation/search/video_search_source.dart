import 'package:melodix/features/video/presentation/widgets/video_row_actions.dart';

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/search/search_sources.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/usecases/watch_videos_usecase.dart';
import 'package:melodix/features/video/presentation/navigation/video_player_navigation.dart';
import 'package:melodix/features/video/presentation/widgets/video_tile.dart';

/// Lets the library search find videos, by title.
///
/// Searches the saved library in memory (no database read per keystroke).
/// The library is only loaded the first time a search runs, so the app
/// doesn't read every video at launch just in case.
class VideoSearchSource extends ChangeNotifier implements SearchSource {
  VideoSearchSource(this._watchVideos);

  final WatchVideosUseCase _watchVideos;
  StreamSubscription<List<Video>>? _subscription;

  List<Video> _videos = const [];

  /// Lower-case titles, prepared once per library change.
  List<String> _keys = const [];

  @override
  SearchSection? search(String query) {
    _subscription ??= _watchVideos().listen((videos) {
      _videos = videos;
      _keys = [for (final v in videos) v.title.toLowerCase()];
      notifyListeners(); // open results include them now
    });
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;
    final hits = [
      for (var i = 0; i < _videos.length; i++)
        if (_keys[i].contains(q)) _videos[i],
    ];
    if (hits.isEmpty) return null;
    return SearchSection(
      title: AppStrings.videos,
      count: hits.length,
      itemBuilder: (context, index) => VideoTile(
        video: hits[index],
        // Play the matching videos, starting with this one.
        onTap: () => openVideoPlayer(context, hits, index),
        trailing: VideoRowActions(video: hits[index]),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
