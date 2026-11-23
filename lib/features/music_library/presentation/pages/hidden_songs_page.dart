import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_hidden_songs_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_actions_scope.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_tile.dart';

/// Songs the user hid from the library, with a way to bring them back.
class HiddenSongsPage extends StatefulWidget {
  const HiddenSongsPage({super.key});

  @override
  State<HiddenSongsPage> createState() => _HiddenSongsPageState();
}

class _HiddenSongsPageState extends State<HiddenSongsPage> {
  late final Stream<List<Song>> _hiddenSongs =
      getIt<WatchHiddenSongsUseCase>()();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.hiddenSongs)),
      body: SongActionsScope(
        child: StreamBuilder<List<Song>>(
          stream: _hiddenSongs,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final songs = snapshot.data!;
            if (songs.isEmpty) {
              return const LibraryStatusView(
                icon: Icons.visibility_rounded,
                title: AppStrings.noHiddenSongs,
                message: AppStrings.noHiddenSongsSubtitle,
              );
            }
            return ListView.builder(
              padding: EdgeInsets.only(
                top: 8.h,
                bottom: MediaQuery.paddingOf(context).bottom + 16.h,
              ),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return SongTile(
                  song: song,
                  trailing: TextButton(
                    onPressed: () =>
                        context.read<SongActionsCubit>().unhide(song.id),
                    child: Text(
                      AppStrings.unhide,
                      style: TextStyle(color: primary),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
