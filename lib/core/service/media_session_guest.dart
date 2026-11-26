import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// What a guest player shows in the system's media controls while it owns
/// them (the notification, the lock screen, headset buttons).
class GuestMedia extends Equatable {
  const GuestMedia({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.position,
    required this.playing,
    this.loading = false,
    this.completed = false,
    this.hasNext = false,
  });

  /// Unique among guests and songs (e.g. "video:123").
  final String id;
  final String title;
  final String subtitle;
  final Duration duration;
  final Duration position;
  final bool playing;
  final bool loading;
  final bool completed;
  final bool hasNext;

  /// Equal apart from where playback is (the system moves the position on
  /// by itself while playing).
  bool sameApartFromPosition(GuestMedia other) =>
      id == other.id &&
      title == other.title &&
      subtitle == other.subtitle &&
      duration == other.duration &&
      playing == other.playing &&
      loading == other.loading &&
      completed == other.completed &&
      hasNext == other.hasNext;

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    duration,
    position,
    playing,
    loading,
    completed,
    hasNext,
  ];
}

/// A player other than the music (the video) that can take over the
/// system's one media session.
///
/// While [current] isn't null the guest owns it: the notification, lock
/// screen and headset / Bluetooth buttons show and control the guest. When
/// it goes back to null, the music gets them back.
///
/// The music's background handler talks only to this, so it never depends
/// on the video feature.
abstract interface class MediaSessionGuest {
  /// The guest's state while it owns the controls; null while the music
  /// does.
  GuestMedia? get current;

  /// Every change of [current] (position ticks included: the listener
  /// decides what's worth sending on).
  Stream<GuestMedia?> get changes;

  /// The picture for the notification and lock screen, or null for the
  /// app's branded cover.
  Future<Uint8List?> artwork(String id);

  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);

  /// Jumps back / forward by the user's skip length.
  Future<void> rewind();
  Future<void> fastForward();

  /// The next item, or a jump forward when there's none.
  Future<void> next();

  /// Back to the start, or the previous item.
  Future<void> previous();
}
