import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/library_metadata_collection.dart';
import 'package:melodix/core/database/collections/playback_state_collection.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/core/database/collections/recent_music_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/collections/video_collection.dart';
import 'package:melodix/core/database/collections/video_progress_collection.dart';
import 'package:path_provider/path_provider.dart';

/// Opens the app's single Isar instance. Register new collection schemas in
/// [schemas].
class IsarDatabase {
  IsarDatabase._();

  static const List<CollectionSchema<dynamic>> schemas = [
    SongCollectionSchema,
    PlaylistCollectionSchema,
    RecentMusicCollectionSchema,
    PlaybackStateCollectionSchema,
    LibraryMetadataCollectionSchema,
    VideoCollectionSchema,
    VideoProgressCollectionSchema,
  ];

  static Future<Isar> open() async {
    final existing = Isar.getInstance();
    if (existing != null) return existing;

    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(schemas, directory: dir.path, name: 'melodix');
  }
}
