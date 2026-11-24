import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/database/recent_music_local_storage.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/music_library/data/repositories/recently_played_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class MockRecentStorage extends Mock implements RecentMusicLocalStorage {}

void main() {
  late MockRecentStorage storage;
  late RecentlyPlayedRepositoryImpl repository;

  setUp(() {
    storage = MockRecentStorage();
    repository = RecentlyPlayedRepositoryImpl(
      storage: storage,
      mapper: const SongMapper(isAndroid: true),
    );
  });

  test('history comes out as songs, newest first, live', () async {
    when(() => storage.watchRecentSongs())
        .thenAnswer((_) => Stream.value([songRow(5), songRow(2)]));

    final songs = await repository.watchRecentlyPlayed().first;

    expect(songs.map((s) => s.id), [5, 2]);
  });

  test('clearing forgets the history', () async {
    when(() => storage.clearRecent()).thenAnswer((_) async {});

    expect((await repository.clearRecentlyPlayed()).isRight(), isTrue);
    verify(() => storage.clearRecent()).called(1);
  });

  test('a failed clear is a LibraryFailure', () async {
    when(() => storage.clearRecent()).thenThrow(Exception('db'));

    final result = await repository.clearRecentlyPlayed();

    expect(result.fold((f) => f, (_) => null), isA<LibraryFailure>());
  });
}
