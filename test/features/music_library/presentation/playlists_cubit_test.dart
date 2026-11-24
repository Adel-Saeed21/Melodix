import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/usecases/create_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/delete_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/rename_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_playlist_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_playlists_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockWatch extends Mock implements WatchPlaylistsUseCase {}

class MockCreate extends Mock implements CreatePlaylistUseCase {}

class MockRename extends Mock implements RenamePlaylistUseCase {}

class MockDelete extends Mock implements DeletePlaylistUseCase {}

class MockToggle extends Mock implements TogglePlaylistFavoriteUseCase {}

const _playlist = Playlist(
  id: 1,
  name: 'Gym',
  songCount: 3,
  isFavorite: false,
  artworkSongId: 5,
);

void main() {
  late StreamController<List<Playlist>> stream;
  late MockCreate create;
  late MockRename rename;
  late MockDelete delete;
  late MockToggle toggle;
  late PlaylistsCubit cubit;

  setUpAll(() {
    registerFallbackValue(const CreatePlaylistParams(''));
    registerFallbackValue(const RenamePlaylistParams(0, ''));
  });

  setUp(() {
    stream = StreamController<List<Playlist>>.broadcast();
    final watch = MockWatch();
    when(() => watch()).thenAnswer((_) => stream.stream);
    create = MockCreate();
    rename = MockRename();
    delete = MockDelete();
    toggle = MockToggle();
    cubit = PlaylistsCubit(
      watchPlaylists: watch,
      createPlaylist: create,
      renamePlaylist: rename,
      deletePlaylist: delete,
      toggleFavorite: toggle,
    );
  });

  tearDown(() async {
    await cubit.close();
    await stream.close();
  });

  test('follows the live playlist list', () async {
    expect(cubit.state.isLoading, isTrue);

    stream.add(const [_playlist]);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.playlists, [_playlist]);
    expect(cubit.state.byId(1), _playlist);
    expect(cubit.state.byId(2), isNull);
  });

  test('create trims the name and reports it', () async {
    when(() => create(any())).thenAnswer((_) async => const Right(9));

    await cubit.create('  Focus ');

    final params =
        verify(() => create(captureAny())).captured.single
            as CreatePlaylistParams;
    expect(params.name, 'Focus');
    expect(cubit.state.feedback?.message, 'Created "Focus"');
    expect(cubit.state.feedback?.isError, isFalse);
  });

  test('rename, favourite and delete report feedback', () async {
    when(() => rename(any())).thenAnswer((_) async => const Right(unit));
    when(() => toggle(1)).thenAnswer((_) async => const Right(true));
    when(() => delete(1)).thenAnswer((_) async => const Right(unit));

    await cubit.rename(_playlist, 'Leg day');
    expect(cubit.state.feedback?.message, 'Playlist renamed');

    await cubit.toggleFavorite(_playlist);
    expect(cubit.state.feedback?.message, 'Playlist added to favourites');

    final sequence = cubit.state.feedback!.sequence;
    await cubit.delete(_playlist);
    expect(cubit.state.feedback?.message, 'Playlist deleted');
    expect(cubit.state.feedback!.sequence, sequence + 1);
  });

  test('failures surface their message', () async {
    when(() => delete(1))
        .thenAnswer((_) async => const Left(LibraryFailure('Nope')));

    await cubit.delete(_playlist);

    expect(cubit.state.feedback?.message, 'Nope');
    expect(cubit.state.feedback?.isError, isTrue);
  });
}
