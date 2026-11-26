import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/lyrics/domain/entities/lyrics.dart';
import 'package:melodix/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

enum LyricsStatus {
  /// Looking on the phone.
  loading,

  /// Showing [LyricsState.lyrics].
  found,

  /// None on the phone: online search offered.
  none,

  /// Searching online.
  searching,

  /// Online had none either.
  notFound,

  /// Online search failed (no connection…).
  failed,
}

class LyricsState extends Equatable {
  const LyricsState({
    this.songId,
    this.status = LyricsStatus.loading,
    this.lyrics,
  });

  final int? songId;
  final LyricsStatus status;
  final Lyrics? lyrics;

  @override
  List<Object?> get props => [songId, status, lyrics];
}

/// The playing song's lyrics for Now Playing: what's on the phone, and an
/// online search when the user asks.
class LyricsCubit extends Cubit<LyricsState> {
  LyricsCubit(this._repository) : super(const LyricsState());

  final LyricsRepository _repository;
  Song? _song;

  /// Shows [song]'s lyrics (nothing to do if it's already the one shown).
  Future<void> show(Song song) async {
    if (_song?.id == song.id) return;
    _song = song;
    emit(LyricsState(songId: song.id));
    final lyrics = await _repository.local(song);
    if (isClosed || _song?.id != song.id) return;
    emit(
      LyricsState(
        songId: song.id,
        status: lyrics == null ? LyricsStatus.none : LyricsStatus.found,
        lyrics: lyrics,
      ),
    );
  }

  Future<void> searchOnline() async {
    final song = _song;
    if (song == null || state.status == LyricsStatus.searching) return;
    emit(LyricsState(songId: song.id, status: LyricsStatus.searching));
    final result = await _repository.searchOnline(song);
    if (isClosed || _song?.id != song.id) return;
    emit(
      result.fold(
        (_) => LyricsState(songId: song.id, status: LyricsStatus.failed),
        (lyrics) => LyricsState(
          songId: song.id,
          status: lyrics == null ? LyricsStatus.notFound : LyricsStatus.found,
          lyrics: lyrics,
        ),
      ),
    );
  }

  /// Drops lyrics saved from online (wrong song) and shows what's left.
  Future<void> removeSaved() async {
    final song = _song;
    if (song == null) return;
    await _repository.forgetSaved(song.id);
    _song = null;
    await show(song);
  }
}
