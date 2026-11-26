import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/search/search_sources.dart';
import 'package:melodix/features/video/presentation/search/video_search_source.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/widgets/music_home_view.dart';

/// Home = the Music tab: the user's local music library (whose search also
/// finds videos).
class HomeScreenPage extends StatelessWidget {
  const HomeScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocProvider.value(
          value: getIt<MusicLibraryBloc>(),
          // The search also finds videos.
          child: SearchSources(
            sources: [getIt<VideoSearchSource>()],
            child: const MusicHomeView(),
          ),
        ),
      ),
    );
  }
}
