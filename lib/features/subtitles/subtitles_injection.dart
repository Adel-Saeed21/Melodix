import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_api.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_config.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_remote_data_source.dart';
import 'package:melodix/features/subtitles/data/datasources/subtitle_device_source.dart';
import 'package:melodix/features/subtitles/data/datasources/subtitle_local_storage.dart';
import 'package:melodix/features/subtitles/data/repositories/subtitle_repository_impl.dart';
import 'package:melodix/features/subtitles/domain/repositories/subtitle_repository.dart';
import 'package:melodix/features/subtitles/domain/usecases/subtitle_usecases.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitles_cubit.dart';

import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:melodix/features/video/domain/usecases/get_video_playback_uri_usecase.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';

/// Subtitles: files next to the video, imported, or downloaded from
/// OpenSubtitles and kept, so all of them work offline.
void registerSubtitles(GetIt getIt) {
  final config = OpenSubtitlesConfig.fromEnvironment();
  getIt
    ..registerLazySingleton<SubtitleRepository>(
      () => SubtitleRepositoryImpl(
        storage: SubtitleLocalStorage(
          root: () async => Directory(
            p.join((await getApplicationSupportDirectory()).path, 'subtitles'),
          ),
        ),
        device: SubtitleDeviceSourceImpl(),
        remote: OpenSubtitlesRemoteDataSource(
          config: config,
          api: OpenSubtitlesApi(
            OpenSubtitlesRemoteDataSource.createDio(config),
          ),
          files: OpenSubtitlesRemoteDataSource.createFileDio(config),
        ),
        playbackUri: (id) => getIt<GetVideoPlaybackUriUseCase>()(id),
      ),
    )
    ..registerLazySingleton(() => GetSubtitleTracksUseCase(getIt()))
    ..registerLazySingleton(() => LoadSubtitleUseCase(getIt()))
    ..registerLazySingleton(() => SubtitleSelectionUseCase(getIt()))
    ..registerLazySingleton(() => ImportSubtitleUseCase(getIt()))
    ..registerLazySingleton(() => SearchOnlineSubtitlesUseCase(getIt()))
    ..registerLazySingleton(() => DownloadSubtitleUseCase(getIt()))
    ..registerLazySingleton<SubtitlesCubit>(() {
      final session = getIt<VideoPlayerCubit>();
      String? videoOf(VideoPlayerState s) => s.isActive ? s.video.id : null;
      return SubtitlesCubit(
        getTracks: getIt(),
        load: getIt(),
        selection: getIt(),
        import: getIt(),
        currentVideo: session.stream.map(videoOf).distinct(),
        initialVideo: videoOf(session.state),
      );
    }, dispose: (cubit) => cubit.close());
}
