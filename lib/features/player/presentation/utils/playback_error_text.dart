import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/player/domain/entities/playback_error.dart';

/// What to tell the user about [error], in [l10n]'s language.
String playbackErrorText(PlaybackError error, AppLocalizations l10n) =>
    switch (error) {
      PlaybackError.cannotPlay => l10n.cantPlaySong,
    };
