import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/features/player/domain/entities/playback_error.dart';

/// What to tell the user about [error].
String playbackErrorText(PlaybackError error) => switch (error) {
  PlaybackError.cannotPlay => AppStrings.cantPlaySong,
};
