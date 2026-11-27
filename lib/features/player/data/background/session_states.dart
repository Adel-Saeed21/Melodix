import 'package:audio_service/audio_service.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/service/media_session_guest.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/player/data/background/media_controls.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';

/// What the system shows (notification, lock screen) for the music and for
/// a video, built from the app's state.

/// A position further than this from where the system expects it counts as
/// a jump (a seek) and is sent; the system moves it on by itself while
/// playing.
const Duration positionDriftTolerance = Duration(milliseconds: 1500);

/// Whether [position] (at [now]) is far from where the system thinks
/// playback is: [sentPosition] at [sentAt], moving on while [playing].
bool positionJumped({
  required Duration position,
  required DateTime now,
  required Duration sentPosition,
  required DateTime sentAt,
  required bool playing,
}) {
  final expected = playing
      ? sentPosition + now.difference(sentAt)
      : sentPosition;
  return (position - expected).abs() > positionDriftTolerance;
}

/// What the system shows for [song]: its title, then "Artist · Album".
/// Missing tags (saved as "Unknown artist" / "Unknown album") are left out
/// of the subtitle and not reported as real artist or album names.
MediaItem songMediaItem(
  Song song, {
  required Duration duration,
  Uri? artUri,
  AppLocalizations? strings,
}) {
  final title = song.title.trim().isEmpty
      ? (strings ?? const AppLocalizations()).unknownSong
      : song.title;
  final artist = _known(song.artist, unknownArtist);
  final album = _known(song.album, unknownAlbum);
  final subtitle = [?artist, ?album].join(' · ');
  return MediaItem(
    id: '${song.id}',
    title: title,
    artist: artist,
    album: album,
    duration: duration,
    artUri: artUri,
    // The notification and lock screen's two lines.
    displayTitle: title,
    displaySubtitle: subtitle.isEmpty ? unknownArtist : subtitle,
  );
}

String? _known(String value, String unknown) {
  final trimmed = value.trim();
  return trimmed.isEmpty || trimmed == unknown ? null : trimmed;
}

/// The music's state for the system, as last decided ([MusicSent]).
PlaybackState musicPlaybackState(
  NowPlaying state,
  MusicSent sent, {
  required MediaControls controls,
  required Duration position,
  required DateTime now,
}) {
  final hasSong = !sent.stopped;
  return PlaybackState(
    // Android 13+ puts the custom ♥ in the slot left of "previous" and
    // shuffle right of "next". Earlier versions show the other three.
    controls: [
      if (hasSong) controls.favorite(on: sent.favorite),
      controls.previous,
      if (sent.playing) controls.pause else controls.play,
      controls.next,
      if (hasSong) controls.shuffle(on: sent.shuffle),
    ],
    systemActions: const {
      MediaAction.seek,
      MediaAction.skipToQueueItem,
      MediaAction.setRepeatMode,
      MediaAction.setShuffleMode,
    },
    // Previous, play/pause, next in the collapsed notification (Android 12
    // and below). These count only the standard buttons: the custom ♥ and
    // shuffle aren't notification buttons there.
    androidCompactActionIndices: const [0, 1, 2],
    processingState: sent.processing,
    playing: sent.playing,
    updatePosition: position,
    updateTime: now,
    queueIndex: sent.stopped ? null : state.currentIndex,
    repeatMode: switch (state.repeatMode) {
      PlaybackRepeat.off => AudioServiceRepeatMode.none,
      PlaybackRepeat.one => AudioServiceRepeatMode.one,
      PlaybackRepeat.all => AudioServiceRepeatMode.all,
    },
    shuffleMode: state.shuffle
        ? AudioServiceShuffleMode.all
        : AudioServiceShuffleMode.none,
  );
}

/// A video's state for the system: its own back / forward jumps in the
/// music's ♥ and shuffle slots (Android 13+).
PlaybackState guestPlaybackState(
  GuestMedia media, {
  required MediaControls controls,
  required DateTime now,
}) => PlaybackState(
  controls: [
    controls.rewind,
    controls.previous,
    if (media.playing) controls.pause else controls.play,
    controls.next,
    controls.forward,
  ],
  systemActions: const {
    MediaAction.seek,
    MediaAction.fastForward,
    MediaAction.rewind,
  },
  androidCompactActionIndices: const [0, 1, 2],
  processingState: media.loading
      ? AudioProcessingState.loading
      : media.completed
      ? AudioProcessingState.completed
      : AudioProcessingState.ready,
  playing: media.playing,
  updatePosition: media.position,
  updateTime: now,
);

/// A video's details for the system.
MediaItem guestMediaItem(GuestMedia media, {Uri? artUri}) => MediaItem(
  id: media.id,
  title: media.title,
  artist: media.subtitle,
  duration: media.duration,
  artUri: artUri,
  displayTitle: media.title,
  displaySubtitle: media.subtitle,
);

/// What was last sent to the system for the music (minus the position's
/// natural drift), to skip sending repeats.
class MusicSent {
  const MusicSent({
    required this.playing,
    required this.processing,
    required this.stopped,
    required this.index,
    required this.repeat,
    required this.shuffle,
    required this.favorite,
    this.position = Duration.zero,
    required this.time,
  });

  factory MusicSent.of(
    NowPlaying state, {
    required bool stopped,
    required bool favorite,
  }) => MusicSent(
    playing: !stopped && state.isPlaying,
    processing: stopped
        ? AudioProcessingState.idle
        : state.isLoading
        ? AudioProcessingState.loading
        : state.isCompleted
        ? AudioProcessingState.completed
        : AudioProcessingState.ready,
    stopped: stopped,
    index: state.currentIndex,
    repeat: state.repeatMode,
    shuffle: state.shuffle,
    favorite: favorite,
    time: DateTime.fromMillisecondsSinceEpoch(0),
  );

  final bool playing;
  final AudioProcessingState processing;
  final bool stopped;
  final int? index;
  final PlaybackRepeat repeat;
  final bool shuffle;
  final bool favorite;
  final Duration position;
  final DateTime time;

  MusicSent at(Duration position, DateTime time) => MusicSent(
    playing: playing,
    processing: processing,
    stopped: stopped,
    index: index,
    repeat: repeat,
    shuffle: shuffle,
    favorite: favorite,
    position: position,
    time: time,
  );

  bool sameApartFromPosition(MusicSent other) =>
      playing == other.playing &&
      processing == other.processing &&
      stopped == other.stopped &&
      index == other.index &&
      repeat == other.repeat &&
      shuffle == other.shuffle &&
      favorite == other.favorite;
}
