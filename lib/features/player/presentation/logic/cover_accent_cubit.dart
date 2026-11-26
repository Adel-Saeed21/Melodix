import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/cover_palette.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';

/// The playing song's cover colour, for "colours from the cover": null
/// when the setting is off, nothing plays, or the cover has no clear
/// colour (the user's own accent shows then).
///
/// Works only while the setting is on, and once per song.
class CoverAccentCubit extends Cubit<Color?> {
  CoverAccentCubit({
    required Stream<NowPlaying> nowPlaying,
    required NowPlaying current,
    required Stream<UiPreferences> preferences,
    required this._enabled,
    required this._artwork,
    Future<Color?> Function(Uint8List encoded)? pick,
  }) : _pick = pick ?? CoverPalette.fromEncoded,
       _songId = current.currentSong?.id,
       super(null) {
    _subscriptions
      ..add(
        nowPlaying.map((s) => s.currentSong?.id).distinct().listen((id) {
          _songId = id;
          unawaited(_update());
        }),
      )
      ..add(
        preferences.map((p) => p.dynamicAccent).distinct().listen((on) {
          _enabled = on;
          unawaited(_update());
        }),
      );
    unawaited(_update());
  }

  final FutureOr<Uint8List?> Function(int songId) _artwork;
  final Future<Color?> Function(Uint8List encoded) _pick;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Map<int, Color?> _known = {};
  bool _enabled;
  int? _songId;

  Future<void> _update() async {
    final id = _songId;
    if (!_enabled || id == null) {
      if (!isClosed) emit(null);
      return;
    }
    if (_known.containsKey(id)) {
      emit(_known[id]);
      return;
    }
    Color? color;
    try {
      final bytes = await _artwork(id);
      color = bytes == null ? null : await _pick(bytes);
    } catch (_) {
      color = null;
    }
    if (_known.length > 64) _known.clear();
    _known[id] = color;
    // Only if this is still the song playing (and the setting still on).
    if (!isClosed && _enabled && _songId == id) emit(color);
  }

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    return super.close();
  }
}
