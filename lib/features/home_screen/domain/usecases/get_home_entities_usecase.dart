import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/home_screen/domain/entities/home_entity.dart';
import 'package:melodix/features/home_screen/domain/repositories/home_screen_repository.dart';

class GetHomeEntitiesUseCase {
  const GetHomeEntitiesUseCase(this.repository);

  final HomeScreenRepository repository;

  Future<Either<Failure, List<HomeEntity>>> call() {
    return repository.getHomeEntities();
  }
}
