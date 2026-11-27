import 'package:audio_service/audio_service.dart';
import 'package:melodix/core/l10n/l10n.dart';

/// The buttons the system shows (notification, lock screen), labelled in
/// the app's language at the time they're sent. Icons are in
/// android/app/src/main/res/drawable.
class MediaControls {
  const MediaControls(this._strings);

  /// The texts in the app's language now.
  final AppLocalizations Function() _strings;

  /// Custom action names (sent back by the system when tapped).
  static const String favoriteAction = 'melodix.favorite';
  static const String shuffleAction = 'melodix.shuffle';
  static const String rewindAction = 'melodix.rewind';
  static const String forwardAction = 'melodix.forward';

  MediaControl get previous => MediaControl(
    androidIcon: 'drawable/ic_media_previous',
    label: _strings().previous,
    action: MediaAction.skipToPrevious,
  );

  MediaControl get play => MediaControl(
    androidIcon: 'drawable/ic_media_play',
    label: _strings().play,
    action: MediaAction.play,
  );

  MediaControl get pause => MediaControl(
    androidIcon: 'drawable/ic_media_pause',
    label: _strings().pause,
    action: MediaAction.pause,
  );

  MediaControl get next => MediaControl(
    androidIcon: 'drawable/ic_media_next',
    label: _strings().next,
    action: MediaAction.skipToNext,
  );

  /// The video's back jump.
  MediaControl get rewind => MediaControl(
    androidIcon: 'drawable/ic_media_rewind',
    label: _strings().mediaRewind,
    action: MediaAction.custom,
    customAction: const CustomMediaAction(name: rewindAction),
  );

  /// The video's forward jump.
  MediaControl get forward => MediaControl(
    androidIcon: 'drawable/ic_media_forward',
    label: _strings().mediaForward,
    action: MediaAction.custom,
    customAction: const CustomMediaAction(name: forwardAction),
  );

  MediaControl favorite({required bool on}) => MediaControl.custom(
    androidIcon: on
        ? 'drawable/ic_media_favorite'
        : 'drawable/ic_media_favorite_border',
    label: on ? _strings().removeFromFavourites : _strings().addToFavourites,
    name: favoriteAction,
  );

  MediaControl shuffle({required bool on}) => MediaControl.custom(
    androidIcon: on
        ? 'drawable/ic_media_shuffle_on'
        : 'drawable/ic_media_shuffle',
    label: on ? _strings().turnShuffleOff : _strings().turnShuffleOn,
    name: shuffleAction,
  );
}
