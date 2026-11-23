import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/library_search_results.dart';
import 'package:melodix/features/music_library/domain/usecases/search_library_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockSearch extends Mock implements SearchLibraryUseCase {}

LibrarySearchResults _resultsFor(String name) => LibrarySearchResults(
  artists: [Artist(name: name, songCount: 1, albumCount: 1, artworkSongId: 1)],
);

void main() {
  late MockSearch search;

  setUp(() => search = MockSearch());

  LibrarySearchCubit build() => LibrarySearchCubit(
    search: search,
    debounce: const Duration(milliseconds: 20),
  );

  Future<void> wait([int ms = 40]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  test('debounces typing into one search for the final text', () async {
    when(() => search(any())).thenAnswer((i) async {
      return Right(_resultsFor(i.positionalArguments.first as String));
    });
    final cubit = build();

    cubit
      ..queryChanged('n')
      ..queryChanged('no')
      ..queryChanged(' nov ');
    expect(cubit.state.isLoading, isTrue);
    expect(cubit.state.query, 'nov');
    await wait();

    verify(() => search('nov')).called(1);
    verifyNever(() => search('n'));
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.results.artists.single.name, 'nov');
    await cubit.close();
  });

  test('ignores results of an older search that finish late', () async {
    final slow = Completer<Either<Failure, LibrarySearchResults>>();
    when(() => search('old')).thenAnswer((_) => slow.future);
    when(() => search('new'))
        .thenAnswer((_) async => Right(_resultsFor('new')));
    final cubit = build();

    cubit.queryChanged('old');
    await wait(); // "old" is now in flight
    cubit.queryChanged('new');
    await wait();
    slow.complete(Right(_resultsFor('old')));
    await wait(5);

    expect(cubit.state.query, 'new');
    expect(cubit.state.results.artists.single.name, 'new');
    await cubit.close();
  });

  test('clearing resets to the empty prompt', () async {
    when(() => search(any())).thenAnswer((_) async => Right(_resultsFor('x')));
    final cubit = build();
    cubit.queryChanged('x');
    await wait();

    cubit.clear();

    expect(cubit.state.hasQuery, isFalse);
    expect(cubit.state.results.isEmpty, isTrue);
    expect(cubit.state.isLoading, isFalse);
    await cubit.close();
  });

  test('refresh re-runs the current search', () async {
    when(() => search('x')).thenAnswer((_) async => Right(_resultsFor('x')));
    final cubit = build();
    cubit.queryChanged('x');
    await wait();

    await cubit.refresh();

    verify(() => search('x')).called(2);
    await cubit.close();
  });

  test('failures surface their message', () async {
    when(() => search(any()))
        .thenAnswer((_) async => const Left(LibraryFailure('db')));
    final cubit = build();

    cubit.queryChanged('x');
    await wait();

    expect(cubit.state.errorMessage, 'db');
    await cubit.close();
  });
}
