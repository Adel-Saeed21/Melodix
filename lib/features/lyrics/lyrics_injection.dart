import 'package:path_provider/path_provider.dart';

import 'package:get_it/get_it.dart';
import 'package:melodix/features/lyrics/data/lrclib_client.dart';
import 'package:melodix/features/lyrics/data/lyrics_repository_impl.dart';
import 'package:melodix/features/lyrics/domain/repositories/lyrics_repository.dart';

void registerLyrics(GetIt getIt) {
  // Lyrics: saved, beside the song, in its tags; LRCLIB when asked.
  getIt.registerLazySingleton<LyricsRepository>(
    () => LyricsRepositoryImpl(
      savedDirectory: getApplicationDocumentsDirectory,
      online: LrclibClient(),
    ),
  );
}
