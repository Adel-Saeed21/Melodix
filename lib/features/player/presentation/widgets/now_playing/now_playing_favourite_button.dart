import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';

/// Heart showing whether [song] is a favourite, live: it follows the song's
/// own flag in storage (no scan of the library), so a change made anywhere
/// (a menu, the notification's ♥) shows here at once.
class NowPlayingFavouriteButton extends StatefulWidget {
  const NowPlayingFavouriteButton({super.key, required this.song});

  final Song song;

  @override
  State<NowPlayingFavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends State<NowPlayingFavouriteButton> {
  late Stream<bool> _favorite = _watch();

  Stream<bool> _watch() =>
      context.read<SongActionsCubit>().watchFavorite(widget.song);

  @override
  void didUpdateWidget(NowPlayingFavouriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) _favorite = _watch();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return StreamBuilder<bool>(
      stream: _favorite,
      // The queue's copy until storage answers (right away, normally).
      initialData: widget.song.isFavorite,
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? widget.song.isFavorite;
        return IconButton(
          tooltip: isFavorite
              ? context.l10n.removeFromFavourites
              : context.l10n.addToFavourites,
          onPressed: () =>
              context.read<SongActionsCubit>().toggleFavorite(widget.song),
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? primary : onSurface.withValues(alpha: 0.7),
          ),
        );
      },
    );
  }
}
