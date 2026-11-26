import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/lyrics/domain/entities/lyrics.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

/// A song's lyrics, from the phone first and online when asked.
abstract interface class LyricsRepository {
  /// Lyrics already on the phone: saved earlier, an `.lrc` file next to
  /// the song, or the song's own tags. Null if there are none.
  Future<Lyrics?> local(Song song);

  /// Looks the song up online (LRCLIB) and saves what it finds, so it
  /// works offline next time. Right(null): nothing found.
  Future<Either<Failure, Lyrics?>> searchOnline(Song song);

  /// Forgets lyrics saved from online for [songId].
  Future<void> forgetSaved(int songId);
}
