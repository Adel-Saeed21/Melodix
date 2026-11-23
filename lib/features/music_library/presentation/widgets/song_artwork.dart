import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';

/// A song's embedded cover art, with a themed placeholder while loading or
/// when the song has none.
class SongArtwork extends StatefulWidget {
  const SongArtwork({
    super.key,
    required this.songId,
    required this.size,
    this.circle = false,
    this.placeholderIcon = Icons.music_note_rounded,
  });

  final int songId;

  /// Logical width and height.
  final double size;
  final bool circle;
  final IconData placeholderIcon;

  @override
  State<SongArtwork> createState() => _SongArtworkState();
}

class _SongArtworkState extends State<SongArtwork> {
  Future<Uint8List?>? _artwork;
  int? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadIfNeeded();
  }

  @override
  void didUpdateWidget(SongArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId) _loadIfNeeded();
  }

  void _loadIfNeeded() {
    if (_loadedFor == widget.songId) return;
    _loadedFor = widget.songId;
    // Request enough pixels for a sharp image on this screen.
    final pixels = (widget.size * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(64, 1024);
    _artwork = getIt<GetSongArtworkUseCase>()(
      SongArtworkParams(widget.songId, size: pixels),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.circle
        ? BorderRadius.circular(widget.size)
        : BorderRadius.circular(widget.size * 0.18);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox.square(
        dimension: widget.size,
        child: FutureBuilder<Uint8List?>(
          future: _artwork,
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes == null || bytes.isEmpty) {
              return _Placeholder(icon: widget.placeholderIcon);
            }
            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) =>
                  _Placeholder(icon: widget.placeholderIcon),
            );
          },
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.primaryColor.withValues(alpha: 0.14),
      child: LayoutBuilder(
        builder: (context, constraints) => Icon(
          icon,
          color: theme.primaryColor,
          size: (constraints.maxWidth * 0.45).clamp(16.r, 96.r),
        ),
      ),
    );
  }
}
