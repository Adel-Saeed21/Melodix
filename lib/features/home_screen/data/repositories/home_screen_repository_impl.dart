import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/home_screen/data/data_sources/home_screen_local_data_source.dart';
import 'package:melodix/features/home_screen/domain/entities/home_entity.dart';
import 'package:melodix/features/home_screen/domain/repositories/home_screen_repository.dart';

class HomeScreenRepositoryImpl implements HomeScreenRepository {
  const HomeScreenRepositoryImpl({
    required this.localDataSource,
  });

  final HomeScreenLocalDataSource localDataSource;

  @override
  Future<Either<Failure, List<HomeEntity>>> getHomeEntities() {
    // TODO: implement getHomeEntities
    throw UnimplementedError();
  }

}
