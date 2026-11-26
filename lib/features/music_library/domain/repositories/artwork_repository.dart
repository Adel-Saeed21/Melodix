import 'dart:async';
import 'dart:typed_data';

/// Songs' embedded cover art.
abstract interface class ArtworkRepository {
  /// Embedded artwork for [songId] at roughly [size] px, or null if none.
  ///
  /// Results are cached in memory. A cached answer comes back synchronously
  /// (not as a [Future]), so a list scrolling back to a song can show its
  /// cover in the same frame instead of flashing a placeholder. Concurrent
  /// requests for the same cover share one load.
  FutureOr<Uint8List?> getArtwork(int songId, {int size = 200});

  /// The cover if it's already in memory, without loading anything: null
  /// when it isn't cached; a record (whose bytes may be null: no cover)
  /// when it is.
  ({Uint8List? bytes})? cachedArtwork(int songId, {int size = 200});
}
